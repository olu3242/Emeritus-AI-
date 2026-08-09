import{createClient}from"@supabase/supabase-js";
import{NextRequest,NextResponse}from"next/server";

const procedures={
  "start-session":"start_learning_session",
  "save-progress":"save_session_progress",
  "submit-assessment":"submit_assessment",
  "submit-constructed":"submit_constructed_response",
  "human-score":"finalize_human_score",
  "mastery-override":"create_mastery_override",
  "recommendation":"transition_recommendation",
  "assign-remediation":"assign_remediation",
  "save-remediation":"save_remediation_progress",
  "start-reassessment":"start_remediation_reassessment",
  "submit-reassessment":"submit_remediation_reassessment",
  "resolve-remediation":"resolve_remediation",
  "no-content":"mark_recommendation_no_content",
  "guardian-dashboard":"guardian_dashboard",
  "administrator-dashboard":"administrator_dashboard",
}as const;

export async function POST(request:NextRequest,{params}:{params:Promise<{action:string}>}){
  const{action}=await params;const procedure=procedures[action as keyof typeof procedures];if(!procedure)return NextResponse.json({error:"Unknown learning operation"},{status:404});
  const authorization=request.headers.get("authorization");if(!authorization?.startsWith("Bearer "))return NextResponse.json({error:"Authentication required"},{status:401});
  const declaredSize=Number(request.headers.get("content-length")??"0");if(declaredSize>65536)return NextResponse.json({error:"Request payload exceeds 64 KiB"},{status:413});
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;if(!url||!key)return NextResponse.json({error:"Learning persistence is not configured"},{status:503});
  let body:Record<string,unknown>;try{const raw=await request.text();if(new TextEncoder().encode(raw).length>65536)return NextResponse.json({error:"Request payload exceeds 64 KiB"},{status:413});body=JSON.parse(raw);}catch{return NextResponse.json({error:"Valid JSON is required"},{status:400});}
  const database=createClient(url,key,{global:{headers:{Authorization:authorization}},auth:{persistSession:false,autoRefreshToken:false}});
  const{data,error}=await database.rpc(procedure as never,body as never);if(error){const denied=error.code==="42501";return NextResponse.json({error:denied?"You are not authorized for this learning operation":error.message},{status:denied?403:409});}
  return NextResponse.json({data},{status:200});
}
