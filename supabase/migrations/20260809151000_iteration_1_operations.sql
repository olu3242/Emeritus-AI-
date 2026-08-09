begin;

create function public.execute_curriculum_import(
  p_organization_id uuid, p_idempotency_key text, p_document jsonb, p_digest text, p_dry_run boolean default false
) returns jsonb language plpgsql security invoker as $$
declare
  prior public.import_runs; authority_id uuid; v_package_id uuid; version_id uuid; provenance_id uuid;
  node jsonb; edge jsonb; creates integer; report jsonb;
begin
  if not public.has_org_role(p_organization_id,array['administrator']::public.app_role[]) then raise exception 'forbidden' using errcode='42501'; end if;
  select * into prior from public.import_runs where organization_id=p_organization_id and idempotency_key=p_idempotency_key;
  if found then
    if prior.source_digest <> p_digest then raise exception 'idempotency key reused with different payload' using errcode='23505'; end if;
    return prior.report || jsonb_build_object('replayed',true,'importRunId',prior.id);
  end if;
  creates=jsonb_array_length(p_document->'nodes')+jsonb_array_length(p_document->'relationships');
  report=jsonb_build_object('valid',true,'digest',p_digest,'creates',creates,'changes',0,'unchanged',0,'replayed',false);
  if p_dry_run then
    insert into public.import_runs(organization_id,package_stable_id,idempotency_key,source_digest,dry_run,status,report,actor_id)
    values(p_organization_id,p_document#>>'{package,stableId}',p_idempotency_key,p_digest,true,'validated',report,auth.uid());
    return report;
  end if;
  insert into public.curriculum_authorities(organization_id,stable_id,name,country_code)
  values(p_organization_id,p_document#>>'{package,authorityStableId}',p_document#>>'{package,authorityStableId}',upper(p_document#>>'{package,countryCode}'))
  on conflict(organization_id,stable_id) do update set name=excluded.name returning id into authority_id;
  insert into public.curriculum_packages(organization_id,authority_id,stable_id,title,country_code)
  values(p_organization_id,authority_id,p_document#>>'{package,stableId}',p_document#>>'{package,title}',upper(p_document#>>'{package,countryCode}'))
  on conflict(organization_id,stable_id) do update set title=excluded.title returning id into v_package_id;
  select id into version_id from public.curriculum_package_versions
    where curriculum_package_versions.package_id=v_package_id and version=p_document#>>'{package,version}' and source_digest=p_digest order by revision desc limit 1;
  if version_id is not null then
    report=report||jsonb_build_object('creates',0,'unchanged',creates,'packageVersionId',version_id);
  else
    insert into public.curriculum_package_versions(organization_id,package_id,version,effective_from,effective_to,terminology,policies,source_digest,revision,created_by)
    values(p_organization_id,v_package_id,p_document#>>'{package,version}',(p_document#>>'{package,effectiveFrom}')::date,
      nullif(p_document#>>'{package,effectiveTo}','')::date,coalesce(p_document#>'{package,terminology}','{}'),coalesce(p_document#>'{package,policies}','{}'),p_digest,
      coalesce((select max(revision)+1 from public.curriculum_package_versions v where v.package_id=v_package_id and v.version=p_document#>>'{package,version}'),1),auth.uid()) returning id into version_id;
    for node in select value from jsonb_array_elements(p_document->'nodes') loop
      insert into public.provenance_records(organization_id,source_url,source_title,publisher,license_id,license_url,retrieved_at,authoritative,digest)
      values(p_organization_id,node#>>'{provenance,sourceUrl}',node#>>'{provenance,sourceTitle}',node#>>'{provenance,publisher}',node#>>'{provenance,licenseId}',node#>>'{provenance,licenseUrl}',(node#>>'{provenance,retrievedAt}')::timestamptz,(node#>>'{provenance,authoritative}')::boolean,encode(digest((node->'provenance')::text,'sha256'),'hex'))
      on conflict(organization_id,digest) do update set source_title=excluded.source_title returning id into provenance_id;
      insert into public.curriculum_nodes(organization_id,package_version_id,stable_id,kind,code,title,description,level_key,subject_key,jurisdiction_key,metadata,provenance_id,content_digest)
      values(p_organization_id,version_id,node->>'stableId',(node->>'kind')::public.curriculum_node_kind,node->>'code',node->>'title',node->>'description',node->>'level',node->>'subject',node->>'jurisdiction',coalesce(node->'metadata','{}'),provenance_id,encode(digest(node::text,'sha256'),'hex'));
    end loop;
    for edge in select value from jsonb_array_elements(p_document->'relationships') loop
      insert into public.curriculum_relationships(organization_id,package_version_id,stable_id,from_node_id,to_node_id,kind,metadata)
      select p_organization_id,version_id,edge->>'stableId',f.id,t.id,(edge->>'kind')::public.curriculum_relationship_kind,coalesce(edge->'metadata','{}')
      from public.curriculum_nodes f, public.curriculum_nodes t where f.package_version_id=version_id and t.package_version_id=version_id and f.stable_id=edge->>'fromStableId' and t.stable_id=edge->>'toStableId';
    end loop;
    report=report||jsonb_build_object('packageVersionId',version_id);
  end if;
  insert into public.import_runs(organization_id,package_stable_id,idempotency_key,source_digest,dry_run,status,report,package_version_id,actor_id)
  values(p_organization_id,p_document#>>'{package,stableId}',p_idempotency_key,p_digest,false,'committed',report,version_id,auth.uid());
  insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id,data)
  values(p_organization_id,auth.uid(),'curriculum.imported','curriculum_package_version',version_id,report);
  return report;
exception when others then raise;
end $$;

create function public.transition_curriculum_version(p_version_id uuid,p_expected_lock integer,p_next public.curriculum_workflow_state,p_reason text default null)
returns public.curriculum_package_versions language plpgsql security invoker as $$
declare current public.curriculum_package_versions; allowed boolean; result public.curriculum_package_versions;
begin
  select * into current from public.curriculum_package_versions where id=p_version_id for update;
  if current.id is null then raise exception 'not found'; end if;
  if current.lock_version <> p_expected_lock then raise exception 'concurrent modification' using errcode='40001'; end if;
  if not public.has_org_role(current.organization_id,array['reviewer','administrator']::public.app_role[]) then raise exception 'forbidden' using errcode='42501'; end if;
  allowed=(current.state,p_next) in (('draft','automated_validation'),('automated_validation','curriculum_review'),('curriculum_review','accessibility_review'),('accessibility_review','approved'),('approved','published'),('published','superseded'),('superseded','archived'));
  if not allowed then raise exception 'invalid workflow transition: % -> %',current.state,p_next; end if;
  if p_next='published' and exists(select 1 from public.curriculum_reviews r where r.package_version_id=p_version_id and r.decision in ('rejected','changes_requested')) then raise exception 'unresolved review rejection'; end if;
  update public.curriculum_package_versions set state=p_next,published_at=case when p_next='published' then now() else published_at end where id=p_version_id returning * into result;
  insert into public.curriculum_reviews(organization_id,package_version_id,review_type,decision,reviewer_id,reason)
  values(current.organization_id,p_version_id,case when p_next='accessibility_review' then 'accessibility_review' when p_next='curriculum_review' then 'curriculum_review' else 'automated_validation' end,'submitted',auth.uid(),p_reason);
  insert into public.audit_events(organization_id,actor_id,event_type,aggregate_type,aggregate_id,data)
  values(current.organization_id,auth.uid(),'curriculum.state_changed','curriculum_package_version',p_version_id,jsonb_build_object('from',current.state,'to',p_next,'reason',p_reason));
  return result;
end $$;

create function public.curriculum_coverage(p_version_id uuid,p_subject text default null,p_level text default null,p_jurisdiction text default null)
returns table(denominator bigint,covered bigint,missing_stable_ids jsonb) language sql stable security invoker as $$
  with requirements as (
    select n.id,n.stable_id from public.curriculum_nodes n join public.curriculum_package_versions v on v.id=n.package_version_id
    where n.package_version_id=p_version_id and v.state='published' and n.kind in ('standard','competency','outcome')
      and (p_subject is null or n.subject_key=p_subject) and (p_level is null or n.level_key=p_level)
      and (p_jurisdiction is null or n.jurisdiction_key is null or n.jurisdiction_key=p_jurisdiction)
  ), mapped as (select distinct r.from_node_id from public.curriculum_relationships r join public.curriculum_nodes n on n.id=r.to_node_id where r.package_version_id=p_version_id and r.kind='aligns_to' and n.kind='objective')
  select count(*),count(m.from_node_id),coalesce(jsonb_agg(q.stable_id) filter(where m.from_node_id is null),'[]') from requirements q left join mapped m on m.from_node_id=q.id;
$$;

grant execute on function public.execute_curriculum_import(uuid,text,jsonb,text,boolean) to authenticated;
grant execute on function public.transition_curriculum_version(uuid,integer,public.curriculum_workflow_state,text) to authenticated;
grant execute on function public.curriculum_coverage(uuid,text,text,text) to authenticated;

commit;
