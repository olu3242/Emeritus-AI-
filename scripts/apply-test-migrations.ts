import { Client } from "pg";
import { readdir,readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { appendFileSync } from "node:fs";

async function main(){
  const url=process.env.TEST_DATABASE_URL;
  if(!url) throw new Error("TEST_DATABASE_URL is required");
  const parsed=new URL(url);
  const database=parsed.pathname.slice(1).toLowerCase();
  if(!["127.0.0.1","localhost"].includes(parsed.hostname)&&!database.includes("test")) throw new Error("Refusing migrations: target must be localhost or have 'test' in its database name");
  const directory=resolve("supabase/migrations"); const files=(await readdir(directory)).filter(f=>f.endsWith(".sql")).sort();
  const client=new Client({connectionString:url}); await client.connect();
  try {
    if(process.env.TEST_DATABASE_BOOTSTRAP==="supabase-compatible"){
      await client.query(await readFile(resolve("tests/integration/bootstrap-supabase.sql"),"utf8"));
      process.stdout.write("applied test-only Supabase compatibility bootstrap\n");
    }
    await client.query("create table if not exists public.emeritus_test_migrations(id text primary key,applied_at timestamptz not null default now())");
    for(const file of files){
      const prior=await client.query("select 1 from public.emeritus_test_migrations where id=$1",[file]);
      if(prior.rowCount) throw new Error(`Refusing reapplication: migration already recorded: ${file}`);
      try{await client.query(await readFile(resolve(directory,file),"utf8"));}
      catch(error){
        const message=(error instanceof Error?error.message:String(error)).replace(/[\r\n]+/g," ").replace(/postgres(?:ql)?:\/\/\S+/gi,"[REDACTED_DATABASE_URL]");
        if(process.env.CI==="true")process.stderr.write(`::error file=supabase/migrations/${file},title=Migration failed::${message}\n`);
        throw error;
      }
      await client.query("insert into public.emeritus_test_migrations(id) values($1)",[file]);
      process.stdout.write(`applied ${file}\n`);
    }
    const recorded=await client.query("select id from public.emeritus_test_migrations order by id");
    if(recorded.rowCount!==files.length) throw new Error(`Migration history mismatch: expected ${files.length}, recorded ${recorded.rowCount}`);
    process.stdout.write(`verified ${recorded.rowCount} migration records\n`);
  } finally { await client.end(); }
}
main().catch(error=>{
  const message=(error instanceof Error?error.message:String(error)).replace(/[\r\n]+/g," ").replace(/postgres(?:ql)?:\/\/\S+/gi,"[REDACTED_DATABASE_URL]");
  console.error(message);
  if(process.env.CI==="true"){
    process.stderr.write(`::error title=Database migration certification failed::${message}\n`);
    if(process.env.GITHUB_STEP_SUMMARY)appendFileSync(process.env.GITHUB_STEP_SUMMARY,`## Database migration failure\n\n${message}\n`);
  }
  process.exitCode=1;
});
