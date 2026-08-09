begin;

alter table public.assessment_items drop constraint assessment_items_item_type_check;
alter table public.assessment_items add constraint assessment_items_item_type_check check(item_type in('single_select','multi_select','numeric_response','short_response','extended_response'));

create table public.rubric_versions(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),assessment_version_id uuid not null references public.assessment_versions(id),
 version integer not null,criteria jsonb not null,state public.learning_publication_state not null default'draft',created_by uuid not null references auth.users(id),published_at timestamptz,created_at timestamptz not null default now(),unique(assessment_version_id,version)
);
create table public.human_score_revisions(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),attempt_id uuid not null references public.assessment_attempts(id),rubric_version_id uuid not null references public.rubric_versions(id),
 revision integer not null,grader_id uuid not null references auth.users(id),criterion_scores jsonb not null,earned numeric(8,2) not null,possible numeric(8,2) not null,rationale text not null,
 status text not null check(status in('draft','finalized','superseded')),idempotency_key text not null,lock_version integer not null default 0,created_at timestamptz not null default now(),finalized_at timestamptz,
 unique(attempt_id,revision),unique(organization_id,idempotency_key),check(length(trim(rationale))>0)
);
create table public.mastery_overrides(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),mastery_decision_id uuid not null references public.mastery_decisions(id),learner_id uuid not null references auth.users(id),
 objective_id uuid not null references public.curriculum_nodes(id),calculated_state public.mastery_state not null,override_state public.mastery_state not null,teacher_id uuid not null references auth.users(id),reason text not null,
 evidence jsonb not null default'{}',status text not null check(status in('active','withdrawn','superseded')),idempotency_key text not null,supersedes_id uuid references public.mastery_overrides(id),created_at timestamptz not null default now(),ended_at timestamptz,
 unique(organization_id,idempotency_key),check(length(trim(reason))>0),check(override_state<>'not_assessed')
);
create table public.recommendation_events(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),recommendation_id uuid not null references public.learning_recommendations(id),actor_id uuid not null references auth.users(id),
 from_status text not null,to_status text not null,reason text not null,replacement_lesson_version_id uuid references public.lesson_versions(id),reassessment_assignment_id uuid references public.assignments(id),
 idempotency_key text not null,created_at timestamptz not null default now(),unique(organization_id,idempotency_key)
);
create table public.assignment_accommodations(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),assignment_id uuid not null references public.assignments(id),learner_id uuid not null references auth.users(id),
 extended_time_multiplier numeric(4,2) not null default 1,allow_pause boolean not null default true,settings jsonb not null default'{}',created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),unique(assignment_id,learner_id)
);
create table public.intervention_notes(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),learner_id uuid not null references auth.users(id),objective_id uuid not null references public.curriculum_nodes(id),
 teacher_id uuid not null references auth.users(id),note text not null,guardian_visible boolean not null default false,created_at timestamptz not null default now(),check(length(trim(note))>0)
);
create table public.learning_outbox(
 id bigint generated always as identity primary key,organization_id uuid not null references public.organizations(id),event_key text not null unique,event_type text not null,payload jsonb not null,
 occurred_at timestamptz not null default now(),processed_at timestamptz,attempts integer not null default 0
);

create index human_score_attempt_idx on public.human_score_revisions(attempt_id,status,revision desc);
create index override_effective_idx on public.mastery_overrides(learner_id,objective_id,status,created_at desc);
create index recommendation_event_idx on public.recommendation_events(recommendation_id,created_at);
create index learning_outbox_pending_idx on public.learning_outbox(occurred_at)where processed_at is null;

alter table public.rubric_versions enable row level security;alter table public.human_score_revisions enable row level security;alter table public.mastery_overrides enable row level security;
alter table public.recommendation_events enable row level security;alter table public.assignment_accommodations enable row level security;alter table public.intervention_notes enable row level security;alter table public.learning_outbox enable row level security;

create policy rubric_teacher_read on public.rubric_versions for select using(public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));
create policy human_score_authorized_read on public.human_score_revisions for select using(public.can_read_assessment_score(attempt_id));
create policy override_authorized_read on public.mastery_overrides for select using(learner_id=auth.uid()or public.has_guardian_access(organization_id,learner_id)or public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));
create policy recommendation_event_teacher_read on public.recommendation_events for select using(public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));
create policy accommodation_participant_read on public.assignment_accommodations for select using(learner_id=auth.uid()or public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));
create policy intervention_teacher_read on public.intervention_notes for select using(teacher_id=auth.uid()or public.has_org_role(organization_id,array['administrator','platform_administrator']::public.app_role[]));
create policy intervention_guardian_read on public.intervention_notes for select using(guardian_visible and public.has_guardian_access(organization_id,learner_id));
create policy outbox_admin_read on public.learning_outbox for select using(public.has_org_role(organization_id,array['administrator','platform_administrator']::public.app_role[]));

grant select on public.rubric_versions,public.human_score_revisions,public.mastery_overrides,public.recommendation_events,public.assignment_accommodations,public.intervention_notes to authenticated;
revoke all on public.learning_outbox from authenticated,anon;

create function public.save_session_progress(p_session uuid,p_expected_lock integer,p_progress jsonb,p_state public.session_state,p_idempotency text) returns public.learning_sessions language plpgsql security definer set search_path='' as $$
declare s public.learning_sessions;r public.learning_sessions;
begin select*into s from public.learning_sessions where id=p_session for update;if s.id is null or s.learner_id<>auth.uid()then raise exception'forbidden'using errcode='42501';end if;if s.lock_version<>p_expected_lock then raise exception'stale progress version'using errcode='40001';end if;
update public.learning_sessions set progress=p_progress,state=p_state,lock_version=lock_version+1,updated_at=now(),completed_at=case when p_state='completed'then now()else completed_at end where id=p_session returning*into r;
insert into public.learning_outbox(organization_id,event_key,event_type,payload)values(s.organization_id,p_idempotency,'learning.progress_saved',jsonb_build_object('sessionId',s.id,'lockVersion',r.lock_version))on conflict(event_key)do nothing;return r;end$$;

create function public.submit_constructed_response(p_assignment uuid,p_idempotency text,p_responses jsonb) returns public.assessment_attempts language plpgsql security definer set search_path='' as $$
declare a public.assignments;e public.class_enrollments;r public.assessment_attempts;
begin select*into a from public.assignments where id=p_assignment and state='active'and(available_from is null or available_from<=now())and(due_at is null or due_at>=now());if a.id is null then raise exception'assignment unavailable';end if;select*into e from public.class_enrollments where class_id=a.class_id and learner_id=auth.uid()and status='active';if e.id is null then raise exception'forbidden'using errcode='42501';end if;
insert into public.assessment_attempts(organization_id,assignment_id,learner_id,assessment_version_id,state,idempotency_key,responses,submitted_at)values(a.organization_id,a.id,auth.uid(),a.assessment_version_id,'pending_human_scoring',p_idempotency,p_responses,now())on conflict(organization_id,idempotency_key)do update set idempotency_key=excluded.idempotency_key returning*into r;
insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id)values(a.organization_id,auth.uid(),'assessment.constructed_submitted','assessment_attempt',r.id);return r;end$$;

create function public.finalize_human_score(p_attempt uuid,p_rubric uuid,p_expected_revision integer,p_criterion_scores jsonb,p_earned numeric,p_possible numeric,p_rationale text,p_idempotency text) returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.assessment_attempts;c public.classes;rv public.rubric_versions;score_revision public.human_score_revisions;objective uuid;decision public.mastery_decisions;ratio numeric;next_state public.mastery_state;kind text;
begin if length(trim(p_rationale))=0 then raise exception'rationale required';end if;select x.*into a from public.assessment_attempts x where x.id=p_attempt for update;select cl.*into c from public.assignments n join public.classes cl on cl.id=n.class_id where n.id=a.assignment_id;if c.teacher_id<>auth.uid()and not public.has_org_role(a.organization_id,array['administrator','platform_administrator']::public.app_role[])then raise exception'forbidden'using errcode='42501';end if;if a.state not in('pending_human_scoring','grading_in_progress')then raise exception'attempt is not gradeable';end if;select*into rv from public.rubric_versions where id=p_rubric and assessment_version_id=a.assessment_version_id and state='published';if rv.id is null then raise exception'published rubric required';end if;
if exists(select 1 from public.human_score_revisions where organization_id=a.organization_id and idempotency_key=p_idempotency)then return jsonb_build_object('replayed',true);end if;if coalesce((select max(h.revision)from public.human_score_revisions h where h.attempt_id=a.id),0)<>p_expected_revision then raise exception'concurrent grading revision'using errcode='40001';end if;
insert into public.human_score_revisions(organization_id,attempt_id,rubric_version_id,revision,grader_id,criterion_scores,earned,possible,rationale,status,idempotency_key,finalized_at)values(a.organization_id,a.id,rv.id,p_expected_revision+1,auth.uid(),p_criterion_scores,p_earned,p_possible,p_rationale,'finalized',p_idempotency,now())returning*into score_revision;
insert into public.assessment_scores(organization_id,attempt_id,scoring_version,earned,possible,outcomes)values(a.organization_id,a.id,'human:'||rv.version,p_earned,p_possible,jsonb_build_object('revision',score_revision.revision,'rubricVersionId',rv.id));update public.assessment_attempts set state='scored',finalized_at=now()where id=a.id;
select objective_id into objective from public.assessment_versions where id=a.assessment_version_id;ratio=case when p_possible=0 then 0 else p_earned/p_possible end;next_state=case when ratio>=.9 then'advanced'::public.mastery_state when ratio>=.75 then'proficient'::public.mastery_state when ratio>=.5 then'developing'::public.mastery_state else'emerging'::public.mastery_state end;kind=case when ratio>=.75 then'enrichment'else'remediation'end;
insert into public.mastery_decisions(organization_id,learner_id,objective_id,attempt_id,previous_state,new_state,ratio,policy_version,evidence,explanation)values(a.organization_id,a.learner_id,objective,a.id,'not_assessed',next_state,ratio,'human-1.0',jsonb_build_object('humanScoreRevisionId',score_revision.id),p_earned||' of '||p_possible||' rubric points')returning*into decision;insert into public.learning_recommendations(organization_id,learner_id,objective_id,mastery_decision_id,kind,reason)values(a.organization_id,a.learner_id,objective,decision.id,kind,'Human-scored evidence decision');
insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id,data)values(a.organization_id,auth.uid(),'assessment.human_scored','assessment_attempt',a.id,jsonb_build_object('revision',score_revision.revision,'rubricVersionId',rv.id));return jsonb_build_object('replayed',false,'revision',score_revision.revision,'mastery',next_state,'recommendation',kind);end$$;

create function public.create_mastery_override(p_decision uuid,p_override public.mastery_state,p_reason text,p_evidence jsonb,p_idempotency text) returns public.mastery_overrides language plpgsql security definer set search_path='' as $$
declare d public.mastery_decisions;c public.classes;r public.mastery_overrides;begin if length(trim(p_reason))=0 then raise exception'reason required';end if;select*into d from public.mastery_decisions where id=p_decision;select cl.*into c from public.assessment_attempts a join public.assignments n on n.id=a.assignment_id join public.classes cl on cl.id=n.class_id where a.id=d.attempt_id;if c.teacher_id<>auth.uid()then raise exception'forbidden'using errcode='42501';end if;
insert into public.mastery_overrides(organization_id,mastery_decision_id,learner_id,objective_id,calculated_state,override_state,teacher_id,reason,evidence,status,idempotency_key)values(d.organization_id,d.id,d.learner_id,d.objective_id,d.new_state,p_override,auth.uid(),p_reason,p_evidence,'active',p_idempotency)on conflict(organization_id,idempotency_key)do update set idempotency_key=excluded.idempotency_key returning*into r;insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id,data)values(d.organization_id,auth.uid(),'mastery.override_recorded','mastery_override',r.id,jsonb_build_object('calculated',d.new_state,'override',p_override,'reason',p_reason));return r;end$$;

create function public.transition_recommendation(p_recommendation uuid,p_to text,p_reason text,p_idempotency text,p_replacement uuid default null,p_reassessment uuid default null) returns public.learning_recommendations language plpgsql security definer set search_path='' as $$
declare r public.learning_recommendations;a public.assessment_attempts;c public.classes;result public.learning_recommendations;begin select*into r from public.learning_recommendations where id=p_recommendation for update;select at.*into a from public.mastery_decisions d join public.assessment_attempts at on at.id=d.attempt_id where d.id=r.mastery_decision_id;select cl.*into c from public.assignments n join public.classes cl on cl.id=n.class_id where n.id=a.assignment_id;if c.teacher_id<>auth.uid()and r.learner_id<>auth.uid()then raise exception'forbidden'using errcode='42501';end if;if p_to not in('accepted','dismissed','completed')then raise exception'invalid recommendation transition';end if;insert into public.recommendation_events(organization_id,recommendation_id,actor_id,from_status,to_status,reason,replacement_lesson_version_id,reassessment_assignment_id,idempotency_key)values(r.organization_id,r.id,auth.uid(),r.status,p_to,p_reason,p_replacement,p_reassessment,p_idempotency)on conflict(organization_id,idempotency_key)do nothing;update public.learning_recommendations set status=p_to where id=r.id returning*into result;return result;end$$;

grant execute on function public.save_session_progress(uuid,integer,jsonb,public.session_state,text),public.submit_constructed_response(uuid,text,jsonb),public.finalize_human_score(uuid,uuid,integer,jsonb,numeric,numeric,text,text),public.create_mastery_override(uuid,public.mastery_state,text,jsonb,text),public.transition_recommendation(uuid,text,text,text,uuid,uuid)to authenticated;

commit;
