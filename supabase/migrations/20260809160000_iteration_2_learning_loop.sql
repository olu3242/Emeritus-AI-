begin;

create type public.learning_publication_state as enum ('draft','in_review','approved','published','superseded','retired');
create type public.assignment_state as enum ('draft','scheduled','active','closed','archived');
create type public.session_state as enum ('not_started','in_progress','paused','completed');
create type public.attempt_state as enum ('created','in_progress','submitted','scoring','scored','reviewed','invalidated');
create type public.mastery_state as enum ('not_assessed','insufficient_evidence','emerging','developing','proficient','advanced');

create table public.classes(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),stable_id text not null,name text not null,
 teacher_id uuid not null references auth.users(id),created_at timestamptz not null default now(),unique(organization_id,stable_id)
);
create table public.class_enrollments(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),class_id uuid not null references public.classes(id),
 learner_id uuid not null references auth.users(id),status text not null check(status in('active','withdrawn')),created_at timestamptz not null default now(),withdrawn_at timestamptz,unique(class_id,learner_id)
);
create table public.guardian_relationships(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),guardian_id uuid not null references auth.users(id),
 learner_id uuid not null references auth.users(id),status text not null check(status in('active','revoked')),verified_at timestamptz not null,revoked_at timestamptz,unique(organization_id,guardian_id,learner_id)
);
create table public.lesson_versions(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),stable_id text not null,version integer not null,
 objective_id uuid not null references public.curriculum_nodes(id),title text not null,state public.learning_publication_state not null default'draft',sections jsonb not null,
 accessibility jsonb not null default'{}',provenance jsonb not null,created_by uuid not null references auth.users(id),published_at timestamptz,created_at timestamptz not null default now(),
 unique(organization_id,stable_id,version),check(state<>'published'or published_at is not null)
);
create table public.assessment_versions(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),stable_id text not null,version integer not null,
 objective_id uuid not null references public.curriculum_nodes(id),title text not null,state public.learning_publication_state not null default'draft',policy_version text not null default'1.0',
 created_by uuid not null references auth.users(id),published_at timestamptz,created_at timestamptz not null default now(),unique(organization_id,stable_id,version)
);
create table public.assessment_items(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),assessment_version_id uuid not null references public.assessment_versions(id),
 stable_id text not null,item_type text not null check(item_type in('single_select')),prompt jsonb not null,answer_key jsonb not null,points numeric(8,2) not null check(points>0),position integer not null,
 unique(assessment_version_id,stable_id),unique(assessment_version_id,position)
);
create table public.assignments(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),class_id uuid not null references public.classes(id),
 lesson_version_id uuid not null references public.lesson_versions(id),assessment_version_id uuid not null references public.assessment_versions(id),state public.assignment_state not null default'draft',
 available_from timestamptz,due_at timestamptz,attempt_limit integer not null default 1 check(attempt_limit>0),created_by uuid not null references auth.users(id),created_at timestamptz not null default now()
);
create table public.learning_sessions(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),assignment_id uuid not null references public.assignments(id),learner_id uuid not null references auth.users(id),
 lesson_version_id uuid not null references public.lesson_versions(id),state public.session_state not null default'not_started',progress jsonb not null default'{}',idempotency_key text not null,lock_version integer not null default 0,
 started_at timestamptz,completed_at timestamptz,updated_at timestamptz not null default now(),unique(organization_id,idempotency_key),unique(assignment_id,learner_id)
);
create table public.assessment_attempts(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),assignment_id uuid not null references public.assignments(id),learner_id uuid not null references auth.users(id),
 assessment_version_id uuid not null references public.assessment_versions(id),state public.attempt_state not null default'created',idempotency_key text not null,responses jsonb not null default'[]',
 submitted_at timestamptz,finalized_at timestamptz,created_at timestamptz not null default now(),unique(organization_id,idempotency_key)
);
create table public.assessment_scores(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),attempt_id uuid not null references public.assessment_attempts(id),
 scoring_version text not null,earned numeric(8,2) not null,possible numeric(8,2) not null,outcomes jsonb not null,created_at timestamptz not null default now(),unique(attempt_id,scoring_version)
);
create table public.mastery_decisions(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),learner_id uuid not null references auth.users(id),objective_id uuid not null references public.curriculum_nodes(id),
 attempt_id uuid not null references public.assessment_attempts(id),previous_state public.mastery_state not null,new_state public.mastery_state not null,ratio numeric(7,4) not null,
 policy_version text not null,evidence jsonb not null,explanation text not null,created_at timestamptz not null default now(),unique(attempt_id,policy_version)
);
create table public.learning_recommendations(
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id),learner_id uuid not null references auth.users(id),objective_id uuid not null references public.curriculum_nodes(id),
 mastery_decision_id uuid not null references public.mastery_decisions(id),kind text not null check(kind in('remediation','enrichment','more_evidence')),reason text not null,
 status text not null default'available' check(status in('available','accepted','dismissed','completed')),created_at timestamptz not null default now(),unique(mastery_decision_id)
);

create index enrollment_learner_idx on public.class_enrollments(learner_id,status);
create index assignment_class_state_idx on public.assignments(class_id,state,available_from);
create index session_learner_idx on public.learning_sessions(learner_id,state,updated_at desc);
create index attempt_learner_idx on public.assessment_attempts(learner_id,state,created_at desc);
create index mastery_learner_objective_idx on public.mastery_decisions(learner_id,objective_id,created_at desc);

alter table public.classes enable row level security;alter table public.class_enrollments enable row level security;alter table public.guardian_relationships enable row level security;
alter table public.lesson_versions enable row level security;alter table public.assessment_versions enable row level security;alter table public.assessment_items enable row level security;
alter table public.assignments enable row level security;alter table public.learning_sessions enable row level security;alter table public.assessment_attempts enable row level security;
alter table public.assessment_scores enable row level security;alter table public.mastery_decisions enable row level security;alter table public.learning_recommendations enable row level security;

create function public.has_guardian_access(p_organization uuid,p_learner uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.guardian_relationships g where g.organization_id=p_organization and g.guardian_id=auth.uid()and g.learner_id=p_learner and g.status='active') $$;
revoke all on function public.has_guardian_access(uuid,uuid)from public;grant execute on function public.has_guardian_access(uuid,uuid)to authenticated;

create policy class_teacher_read on public.classes for select using(teacher_id=auth.uid() or public.has_org_role(organization_id,array['administrator','platform_administrator']::public.app_role[]));
create policy enrollment_participant_read on public.class_enrollments for select using(learner_id=auth.uid() or exists(select 1 from public.classes c where c.id=class_id and c.teacher_id=auth.uid()) or public.has_org_role(organization_id,array['administrator','platform_administrator']::public.app_role[]));
create policy guardian_relationship_read on public.guardian_relationships for select using(guardian_id=auth.uid() or learner_id=auth.uid() or public.has_org_role(organization_id,array['administrator','platform_administrator']::public.app_role[]));
create policy published_lesson_read on public.lesson_versions for select using(state='published' and (public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]) or exists(select 1 from public.assignments a join public.class_enrollments e on e.class_id=a.class_id where a.lesson_version_id=lesson_versions.id and e.learner_id=auth.uid() and e.status='active' and a.state='active')));
create policy published_assessment_read on public.assessment_versions for select using(state='published' and public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));
create policy assignment_participant_read on public.assignments for select using(exists(select 1 from public.classes c where c.id=class_id and c.teacher_id=auth.uid()) or exists(select 1 from public.class_enrollments e where e.class_id=assignments.class_id and e.learner_id=auth.uid() and e.status='active') or public.has_org_role(organization_id,array['administrator','platform_administrator']::public.app_role[]));
create policy own_sessions on public.learning_sessions for select using(learner_id=auth.uid() or exists(select 1 from public.assignments a join public.classes c on c.id=a.class_id where a.id=assignment_id and c.teacher_id=auth.uid()));
create policy own_attempts on public.assessment_attempts for select using(learner_id=auth.uid() or exists(select 1 from public.assignments a join public.classes c on c.id=a.class_id where a.id=assignment_id and c.teacher_id=auth.uid()));
create policy score_authorized_read on public.assessment_scores for select using(exists(select 1 from public.assessment_attempts a join public.assignments x on x.id=a.assignment_id join public.classes c on c.id=x.class_id where a.id=attempt_id and(a.learner_id=auth.uid()or c.teacher_id=auth.uid()or public.has_guardian_access(a.organization_id,a.learner_id))));
create policy mastery_authorized_read on public.mastery_decisions for select using(learner_id=auth.uid()or public.has_guardian_access(organization_id,learner_id)or public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));
create policy recommendation_authorized_read on public.learning_recommendations for select using(learner_id=auth.uid()or public.has_guardian_access(organization_id,learner_id)or public.has_org_role(organization_id,array['educator','administrator','platform_administrator']::public.app_role[]));

grant select on public.classes,public.class_enrollments,public.guardian_relationships,public.lesson_versions,public.assessment_versions,public.assignments,public.learning_sessions,public.assessment_attempts,public.assessment_scores,public.mastery_decisions,public.learning_recommendations to authenticated;
revoke all on public.assessment_items from authenticated,anon;

create function public.start_learning_session(p_assignment uuid,p_idempotency text) returns public.learning_sessions language plpgsql security definer set search_path='' as $$
declare a public.assignments;e public.class_enrollments;r public.learning_sessions;
begin select*into a from public.assignments where id=p_assignment and state='active';if a.id is null then raise exception'assignment unavailable';end if;
select*into e from public.class_enrollments where class_id=a.class_id and learner_id=auth.uid()and status='active';if e.id is null then raise exception'forbidden'using errcode='42501';end if;
insert into public.learning_sessions(organization_id,assignment_id,learner_id,lesson_version_id,state,idempotency_key,started_at)values(a.organization_id,a.id,auth.uid(),a.lesson_version_id,'in_progress',p_idempotency,now())on conflict(assignment_id,learner_id)do update set updated_at=now()returning*into r;
insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id)values(a.organization_id,auth.uid(),'learning.session_started','learning_session',r.id);return r;end$$;
create function public.submit_assessment(p_assignment uuid,p_idempotency text,p_responses jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.assignments;e public.class_enrollments;attempt public.assessment_attempts;objective uuid;earned numeric:=0;possible numeric:=0;outcomes jsonb;decision public.mastery_decisions;ratio numeric;next_state public.mastery_state;kind text;
begin select*into a from public.assignments where id=p_assignment and state='active';if a.id is null then raise exception'assignment unavailable';end if;select*into e from public.class_enrollments where class_id=a.class_id and learner_id=auth.uid()and status='active';if e.id is null then raise exception'forbidden'using errcode='42501';end if;
select*into attempt from public.assessment_attempts where organization_id=a.organization_id and idempotency_key=p_idempotency;if attempt.id is not null then return jsonb_build_object('attemptId',attempt.id,'replayed',true);end if;
insert into public.assessment_attempts(organization_id,assignment_id,learner_id,assessment_version_id,state,idempotency_key,responses,submitted_at,finalized_at)values(a.organization_id,a.id,auth.uid(),a.assessment_version_id,'scored',p_idempotency,p_responses,now(),now())returning*into attempt;
with scored as(select i.id,i.points,case when response_value->>'option'=i.answer_key->>'correctOption'then i.points else 0 end got from public.assessment_items i left join lateral(select value response_value from jsonb_array_elements(p_responses)where value->>'itemId'=i.id::text limit 1)x on true where i.assessment_version_id=a.assessment_version_id),agg as(select coalesce(sum(got),0)earned_total,coalesce(sum(points),0)possible_total,jsonb_agg(jsonb_build_object('itemId',id,'earned',got,'possible',points))outcome_rows from scored)select earned_total,possible_total,outcome_rows into earned,possible,outcomes from agg;
insert into public.assessment_scores(organization_id,attempt_id,scoring_version,earned,possible,outcomes)values(a.organization_id,attempt.id,'1.0',earned,possible,outcomes);select objective_id into objective from public.assessment_versions where id=a.assessment_version_id;ratio=case when possible=0 then 0 else earned/possible end;next_state=case when ratio>=.9 then'advanced'::public.mastery_state when ratio>=.75 then'proficient'::public.mastery_state when ratio>=.5 then'developing'::public.mastery_state else'emerging'::public.mastery_state end;kind=case when ratio>=.75 then'enrichment'else'remediation'end;
insert into public.mastery_decisions(organization_id,learner_id,objective_id,attempt_id,previous_state,new_state,ratio,policy_version,evidence,explanation)values(a.organization_id,auth.uid(),objective,attempt.id,'not_assessed',next_state,ratio,'1.0',jsonb_build_object('score',earned,'possible',possible),earned||' of '||possible||' points')returning*into decision;
insert into public.learning_recommendations(organization_id,learner_id,objective_id,mastery_decision_id,kind,reason)values(a.organization_id,auth.uid(),objective,decision.id,kind,case when kind='enrichment'then'Mastery threshold met'else'Mastery threshold not met'end);
insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id,data)values(a.organization_id,auth.uid(),'assessment.scored','assessment_attempt',attempt.id,jsonb_build_object('scoringVersion','1.0'));return jsonb_build_object('attemptId',attempt.id,'earned',earned,'possible',possible,'mastery',next_state,'recommendation',kind,'replayed',false);end$$;
grant execute on function public.start_learning_session(uuid,text),public.submit_assessment(uuid,text,jsonb)to authenticated;

commit;
