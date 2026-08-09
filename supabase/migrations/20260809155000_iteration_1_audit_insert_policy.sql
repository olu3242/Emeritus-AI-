begin;

create policy audit_privileged_insert on public.audit_events for insert
  with check(public.has_org_role(organization_id,array['reviewer','administrator','platform_administrator']::public.app_role[]));

commit;
