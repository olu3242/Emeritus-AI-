import type { SupabaseClient } from "@supabase/supabase-js";
import type { CurriculumPackageDocument, ImportPlan, ResolutionResult } from "./types";
import { validatePackage } from "./validation";

export class CurriculumService {
  constructor(private readonly database: SupabaseClient) {}

  dryRun(input: unknown): ImportPlan { return validatePackage(input); }

  async import(organizationId: string, idempotencyKey: string, input: unknown, dryRun=false): Promise<Record<string, unknown>> {
    const plan=validatePackage(input); if(!plan.valid) throw new CurriculumValidationError(plan);
    const {data,error}=await this.database.rpc("execute_curriculum_import",{p_organization_id:organizationId,p_idempotency_key:idempotencyKey,p_document:plan.document,p_digest:plan.digest,p_dry_run:dryRun});
    if(error) throw error; return data as Record<string,unknown>;
  }

  async browsePublished(packageVersionId: string, page=1, pageSize=50) {
    if(page<1||pageSize<1||pageSize>100) throw new RangeError("invalid pagination");
    const from=(page-1)*pageSize; const {data,error,count}=await this.database.from("curriculum_nodes").select("stable_id,kind,code,title,description,level_key,subject_key,jurisdiction_key,metadata,provenance_records(source_url,source_title,publisher,license_id,authoritative)",{count:"exact"}).eq("package_version_id",packageVersionId).order("stable_id").range(from,from+pageSize-1);
    if(error) throw error; return {items:data??[],page,pageSize,total:count??0};
  }

  async resolve(packageVersionId: string, subject?: string, level?: string, jurisdiction?: string): Promise<ResolutionResult> {
    let query=this.database.from("curriculum_nodes").select("id,stable_id,kind,code,title,metadata,provenance_records(source_url,source_title,publisher,license_id,license_url,retrieved_at,authoritative)").eq("package_version_id",packageVersionId).in("kind",["standard","competency","outcome","objective"]);
    if(subject) query=query.eq("subject_key",subject); if(level) query=query.eq("level_key",level); if(jurisdiction) query=query.or(`jurisdiction_key.is.null,jurisdiction_key.eq.${jurisdiction}`);
    const {data,error}=await query.order("stable_id"); if(error) throw error;
    const rows=(data??[]) as Array<Record<string,unknown>>; const requirements=rows.filter(r=>r.kind!=="objective");
    return {packageVersionId,requirements,prerequisites:[],policies:{},provenance:[],explanation:[`Resolved published package ${packageVersionId}`,jurisdiction?`Applied jurisdiction ${jurisdiction}`:"Applied base framework"],gaps:requirements.length?[]:["No applicable published requirements"],conflicts:[]};
  }
}

export class CurriculumValidationError extends Error { constructor(public readonly plan: ImportPlan){super("Curriculum package validation failed");} }
export type { CurriculumPackageDocument };
