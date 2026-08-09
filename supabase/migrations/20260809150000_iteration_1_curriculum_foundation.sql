begin;

create extension if not exists pgcrypto;

create type public.app_role as enum ('learner','guardian','educator','reviewer','administrator');
create type public.curriculum_workflow_state as enum ('draft','automated_validation','curriculum_review','accessibility_review','approved','published','superseded','archived');
create type public.curriculum_node_kind as enum ('stage','level','subject','program','course','strand','domain','unit','topic','standard','competency','outcome','objective');
create type public.curriculum_relationship_kind as enum ('contains','prerequisite','progresses_to','aligns_to','replaces','excludes');

create table public.organizations (
  id uuid primary key default gen_random_uuid(), stable_id text not null unique,
  name text not null, created_at timestamptz not null default now()
);
create table public.organization_memberships (
  organization_id uuid not null references public.organizations(id), user_id uuid not null references auth.users(id),
  role public.app_role not null, created_at timestamptz not null default now(),
  primary key (organization_id,user_id,role)
);
create table public.curriculum_authorities (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  stable_id text not null, name text not null, country_code char(2) not null,
  website text, created_at timestamptz not null default now(), unique(organization_id,stable_id)
);
create table public.jurisdictions (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  authority_id uuid references public.curriculum_authorities(id), stable_id text not null,
  country_code char(2) not null, code text not null, name text not null,
  parent_id uuid references public.jurisdictions(id), created_at timestamptz not null default now(),
  unique(organization_id,stable_id)
);
create table public.curriculum_packages (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  authority_id uuid not null references public.curriculum_authorities(id), stable_id text not null,
  title text not null, country_code char(2) not null, jurisdiction_id uuid references public.jurisdictions(id),
  created_at timestamptz not null default now(), unique(organization_id,stable_id)
);
create table public.curriculum_package_versions (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_id uuid not null references public.curriculum_packages(id), version text not null,
  state public.curriculum_workflow_state not null default 'draft', effective_from date not null,
  effective_to date, terminology jsonb not null default '{}', policies jsonb not null default '{}',
  source_digest text not null, revision integer not null default 1, published_at timestamptz,
  supersedes_id uuid references public.curriculum_package_versions(id), lock_version integer not null default 0,
  created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(package_id,version,revision), check(effective_to is null or effective_to >= effective_from),
  check(state <> 'published' or published_at is not null)
);
create unique index one_published_package_revision on public.curriculum_package_versions(package_id,version) where state='published';

create table public.provenance_records (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  source_url text not null, source_title text not null, publisher text not null, license_id text not null,
  license_url text, retrieved_at timestamptz not null, authoritative boolean not null default false,
  digest text not null, created_at timestamptz not null default now(), unique(organization_id,digest)
);
create table public.curriculum_nodes (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_version_id uuid not null references public.curriculum_package_versions(id), stable_id text not null,
  kind public.curriculum_node_kind not null, code text, title text not null, description text,
  level_key text, subject_key text, jurisdiction_key text, metadata jsonb not null default '{}',
  provenance_id uuid not null references public.provenance_records(id), content_digest text not null,
  created_at timestamptz not null default now(), unique(package_version_id,stable_id)
);
create table public.curriculum_relationships (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_version_id uuid not null references public.curriculum_package_versions(id), stable_id text not null,
  from_node_id uuid not null references public.curriculum_nodes(id), to_node_id uuid not null references public.curriculum_nodes(id),
  kind public.curriculum_relationship_kind not null, metadata jsonb not null default '{}',
  created_at timestamptz not null default now(), unique(package_version_id,stable_id), check(from_node_id <> to_node_id)
);
create table public.jurisdiction_overlays (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  base_package_version_id uuid not null references public.curriculum_package_versions(id),
  overlay_package_version_id uuid not null references public.curriculum_package_versions(id),
  jurisdiction_id uuid not null references public.jurisdictions(id), priority integer not null default 0,
  effective_from date not null, effective_to date, created_at timestamptz not null default now(),
  unique(base_package_version_id,overlay_package_version_id,jurisdiction_id),
  check(base_package_version_id <> overlay_package_version_id)
);
create table public.curriculum_reviews (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_version_id uuid not null references public.curriculum_package_versions(id),
  review_type text not null check(review_type in ('automated_validation','curriculum_review','accessibility_review','license_review')),
  decision text not null check(decision in ('submitted','approved','rejected','changes_requested')),
  reviewer_id uuid references auth.users(id), reason text, evidence jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create table public.import_runs (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_stable_id text not null, idempotency_key text not null, source_digest text not null,
  dry_run boolean not null, status text not null check(status in ('validated','committed','failed','retired')),
  report jsonb not null, package_version_id uuid references public.curriculum_package_versions(id),
  actor_id uuid references auth.users(id), created_at timestamptz not null default now(),
  unique(organization_id,idempotency_key)
);
create table public.coverage_snapshots (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_version_id uuid not null references public.curriculum_package_versions(id), subject_key text,
  level_key text, jurisdiction_key text, denominator integer not null, covered integer not null,
  missing_stable_ids jsonb not null default '[]', criteria jsonb not null, created_at timestamptz not null default now(),
  check(denominator >= 0 and covered >= 0 and covered <= denominator)
);
create table public.certification_results (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id),
  package_version_id uuid not null references public.curriculum_package_versions(id), scope jsonb not null,
  status text not null check(status in ('passed','failed','incomplete')), checks jsonb not null,
  evidence jsonb not null, created_at timestamptz not null default now()
);
create table public.audit_events (
  id bigint generated always as identity primary key, organization_id uuid not null references public.organizations(id),
  actor_id uuid references auth.users(id), event_type text not null, aggregate_type text not null,
  aggregate_id uuid, data jsonb not null default '{}', occurred_at timestamptz not null default now()
);

create index curriculum_nodes_browse_idx on public.curriculum_nodes(package_version_id,kind,subject_key,level_key,stable_id);
create index curriculum_nodes_jurisdiction_idx on public.curriculum_nodes(package_version_id,jurisdiction_key) where jurisdiction_key is not null;
create index curriculum_edges_from_idx on public.curriculum_relationships(from_node_id,kind);
create index curriculum_edges_to_idx on public.curriculum_relationships(to_node_id,kind);
create index package_versions_resolution_idx on public.curriculum_package_versions(package_id,state,effective_from,effective_to);
create index audit_events_aggregate_idx on public.audit_events(organization_id,aggregate_type,aggregate_id,occurred_at desc);
create index coverage_scope_idx on public.coverage_snapshots(package_version_id,subject_key,level_key,jurisdiction_key,created_at desc);

create function public.has_org_role(org uuid, allowed public.app_role[]) returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.organization_memberships m where m.organization_id=org and m.user_id=auth.uid() and m.role=any(allowed));
$$;
revoke all on function public.has_org_role(uuid,public.app_role[]) from public;
grant execute on function public.has_org_role(uuid,public.app_role[]) to authenticated;

alter table public.organizations enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.curriculum_authorities enable row level security;
alter table public.jurisdictions enable row level security;
alter table public.curriculum_packages enable row level security;
alter table public.curriculum_package_versions enable row level security;
alter table public.provenance_records enable row level security;
alter table public.curriculum_nodes enable row level security;
alter table public.curriculum_relationships enable row level security;
alter table public.jurisdiction_overlays enable row level security;
alter table public.curriculum_reviews enable row level security;
alter table public.import_runs enable row level security;
alter table public.coverage_snapshots enable row level security;
alter table public.certification_results enable row level security;
alter table public.audit_events enable row level security;

create policy memberships_self on public.organization_memberships for select using(user_id=auth.uid());
create policy org_members_read on public.organizations for select using(public.has_org_role(id,array['learner','guardian','educator','reviewer','administrator']::public.app_role[]));
create policy curriculum_admin_authorities on public.curriculum_authorities for all using(public.has_org_role(organization_id,array['administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['administrator']::public.app_role[]));
create policy curriculum_members_authorities_read on public.curriculum_authorities for select using(public.has_org_role(organization_id,array['learner','guardian','educator','reviewer']::public.app_role[]));
create policy curriculum_admin_jurisdictions on public.jurisdictions for all using(public.has_org_role(organization_id,array['administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['administrator']::public.app_role[]));
create policy curriculum_members_jurisdictions_read on public.jurisdictions for select using(public.has_org_role(organization_id,array['learner','guardian','educator','reviewer']::public.app_role[]));
create policy curriculum_admin_packages on public.curriculum_packages for all using(public.has_org_role(organization_id,array['administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['administrator']::public.app_role[]));
create policy curriculum_members_packages_read on public.curriculum_packages for select using(public.has_org_role(organization_id,array['learner','guardian','educator','reviewer']::public.app_role[]));
create policy privileged_versions on public.curriculum_package_versions for all using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy published_versions_read on public.curriculum_package_versions for select using(state='published' and public.has_org_role(organization_id,array['learner','guardian','educator']::public.app_role[]));
create policy privileged_provenance on public.provenance_records for all using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy published_provenance_read on public.provenance_records for select using(exists(select 1 from public.curriculum_nodes n join public.curriculum_package_versions v on v.id=n.package_version_id where n.provenance_id=provenance_records.id and v.state='published' and public.has_org_role(v.organization_id,array['learner','guardian','educator']::public.app_role[])));
create policy privileged_nodes on public.curriculum_nodes for all using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy published_nodes_read on public.curriculum_nodes for select using(exists(select 1 from public.curriculum_package_versions v where v.id=package_version_id and v.state='published') and public.has_org_role(organization_id,array['learner','guardian','educator']::public.app_role[]));
create policy privileged_relationships on public.curriculum_relationships for all using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy published_relationships_read on public.curriculum_relationships for select using(exists(select 1 from public.curriculum_package_versions v where v.id=package_version_id and v.state='published') and public.has_org_role(organization_id,array['learner','guardian','educator']::public.app_role[]));
create policy privileged_overlays on public.jurisdiction_overlays for all using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy privileged_reviews on public.curriculum_reviews for all using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy admin_imports on public.import_runs for all using(public.has_org_role(organization_id,array['administrator']::public.app_role[])) with check(public.has_org_role(organization_id,array['administrator']::public.app_role[]));
create policy coverage_members_read on public.coverage_snapshots for select using(public.has_org_role(organization_id,array['educator','reviewer','administrator']::public.app_role[]));
create policy coverage_admin_write on public.coverage_snapshots for insert with check(public.has_org_role(organization_id,array['administrator']::public.app_role[]));
create policy certification_members_read on public.certification_results for select using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));
create policy certification_admin_write on public.certification_results for insert with check(public.has_org_role(organization_id,array['administrator']::public.app_role[]));
create policy audit_privileged_read on public.audit_events for select using(public.has_org_role(organization_id,array['reviewer','administrator']::public.app_role[]));

create function public.prevent_published_version_mutation() returns trigger language plpgsql as $$
begin
  if old.state in ('published','superseded','archived') and (new.terminology,new.policies,new.effective_from,new.source_digest) is distinct from (old.terminology,old.policies,old.effective_from,old.source_digest) then
    raise exception 'published curriculum versions are immutable';
  end if;
  new.lock_version=old.lock_version+1; new.updated_at=now(); return new;
end $$;
create trigger immutable_published_version before update on public.curriculum_package_versions for each row execute function public.prevent_published_version_mutation();

create function public.prevent_published_child_mutation() returns trigger language plpgsql as $$
declare version_id uuid; locked boolean;
begin
  version_id=coalesce(new.package_version_id,old.package_version_id);
  select state in ('published','superseded','archived') into locked from public.curriculum_package_versions where id=version_id;
  if locked then raise exception 'children of published curriculum versions are immutable'; end if;
  return coalesce(new,old);
end $$;
create trigger immutable_published_nodes before update or delete on public.curriculum_nodes for each row execute function public.prevent_published_child_mutation();
create trigger immutable_published_edges before update or delete on public.curriculum_relationships for each row execute function public.prevent_published_child_mutation();

commit;
