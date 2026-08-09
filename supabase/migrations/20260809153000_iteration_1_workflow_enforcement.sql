begin;

create or replace function public.prevent_published_version_mutation() returns trigger language plpgsql security invoker as $$
begin
  if new.state is distinct from old.state and not public.has_org_role(old.organization_id,array['reviewer','administrator','platform_administrator']::public.app_role[]) then
    raise exception 'workflow transitions require reviewer or administrator role' using errcode='42501';
  end if;
  if old.state in ('published','superseded','archived') and (new.terminology,new.policies,new.effective_from,new.source_digest) is distinct from (old.terminology,old.policies,old.effective_from,old.source_digest) then
    raise exception 'published curriculum versions are immutable';
  end if;
  new.lock_version=old.lock_version+1; new.updated_at=now(); return new;
end $$;

drop policy if exists org_members_read on public.organizations;
create policy org_members_read on public.organizations for select
  using(public.has_org_role(id,array['learner','guardian','educator','curriculum_author','reviewer','administrator','platform_administrator']::public.app_role[]));

commit;
