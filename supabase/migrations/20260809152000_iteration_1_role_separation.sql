begin;

alter type public.app_role add value if not exists 'curriculum_author';
alter type public.app_role add value if not exists 'platform_administrator';

commit;

begin;

drop policy if exists privileged_versions on public.curriculum_package_versions;
create policy privileged_versions on public.curriculum_package_versions for all
  using(public.has_org_role(organization_id,array['curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]))
  with check(public.has_org_role(organization_id,array['curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]));

drop policy if exists privileged_nodes on public.curriculum_nodes;
create policy privileged_nodes on public.curriculum_nodes for all
  using(public.has_org_role(organization_id,array['curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]))
  with check(public.has_org_role(organization_id,array['curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]));

drop policy if exists privileged_relationships on public.curriculum_relationships;
create policy privileged_relationships on public.curriculum_relationships for all
  using(public.has_org_role(organization_id,array['curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]))
  with check(public.has_org_role(organization_id,array['curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]));

create function public.record_curriculum_review(p_version_id uuid,p_review_type text,p_decision text,p_reason text,p_evidence jsonb default '{}')
returns public.curriculum_reviews language plpgsql security invoker as $$
declare v public.curriculum_package_versions; result public.curriculum_reviews;
begin
  select * into v from public.curriculum_package_versions where id=p_version_id;
  if v.id is null then raise exception 'not found'; end if;
  if not public.has_org_role(v.organization_id,array['reviewer','administrator','platform_administrator']::public.app_role[]) then raise exception 'forbidden' using errcode='42501'; end if;
  if v.created_by=auth.uid() and not public.has_org_role(v.organization_id,array['platform_administrator']::public.app_role[]) then raise exception 'authors cannot approve their own work' using errcode='42501'; end if;
  insert into public.curriculum_reviews(organization_id,package_version_id,review_type,decision,reviewer_id,reason,evidence)
  values(v.organization_id,p_version_id,p_review_type,p_decision,auth.uid(),p_reason,p_evidence) returning * into result;
  insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id,data)
  values(v.organization_id,auth.uid(),'curriculum.review_recorded','curriculum_package_version',p_version_id,jsonb_build_object('reviewType',p_review_type,'decision',p_decision,'reason',p_reason));
  return result;
end $$;

grant execute on function public.record_curriculum_review(uuid,text,text,text,jsonb) to authenticated;

commit;
