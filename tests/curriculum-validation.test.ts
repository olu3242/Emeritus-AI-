import { describe,expect,it } from "vitest";
import { validatePackage } from "../src/curriculum/validation";
import { ConfigurableTerminologyAdapter,OrderedProgressionAdapter,parseCurriculumCsv } from "../src/curriculum/adapters";
import { applyOverlay } from "../src/curriculum/resolution";
import { readFileSync } from "node:fs";

const provenance={sourceUrl:"https://example.edu/framework",sourceTitle:"Fixture",publisher:"Example Authority",licenseId:"CC-BY-4.0",retrievedAt:"2026-08-09T12:00:00.000Z",authoritative:false};
const shell={stableId:"fixture.year-competencies",title:"Interoperability Fixture",authorityStableId:"fixture-authority",countryCode:"GB",version:"1",effectiveFrom:"2026-01-01",terminology:{level:"Year",subject:"Learning area"},policies:{mastery:"competency"},provenance};

describe("package validation",()=>{
  it("accepts a structurally different competency package",()=>{const result=validatePackage({schemaVersion:"1.0",package:shell,nodes:[{stableId:"maths.y3.reason",kind:"competency",title:"Reason with quantities",level:"Year 3",subject:"Maths",provenance}],relationships:[]});expect(result.valid).toBe(true);expect(result.digest).toMatch(/^[a-f0-9]{64}$/);});
  it("is deterministic regardless of object key ordering",()=>{const a=validatePackage({schemaVersion:"1.0",package:shell,nodes:[],relationships:[]});const b=validatePackage({relationships:[],nodes:[],package:shell,schemaVersion:"1.0"});expect(a.digest).toBe(b.digest);});
  it("rejects duplicate identities and unknown relationship endpoints",()=>{const node={stableId:"x",kind:"standard",title:"X",provenance};const result=validatePackage({schemaVersion:"1.0",package:shell,nodes:[node,node],relationships:[{stableId:"e",fromStableId:"x",toStableId:"missing",kind:"prerequisite"}]});expect(result.valid).toBe(false);expect(result.issues.map(i=>i.code)).toEqual(expect.arrayContaining(["duplicate","unknown_endpoint"]));});
  it("imports CSV through the neutral document contract",()=>{const csv='stableId,kind,title,sourceUrl,sourceTitle,publisher,licenseId,retrievedAt,authoritative\nmath.y1.n,competency,Number,https://example.edu,Fixture,Authority,CC-BY-4.0,2026-08-09T12:00:00.000Z,false';expect(validatePackage(parseCurriculumCsv(csv,shell)).valid).toBe(true);});
});

describe("adapters",()=>{it("supports localized terminology and configurable progression",()=>{expect(new ConfigurableTerminologyAdapter().label("level",shell.terminology)).toBe("Year");expect(new OrderedProgressionAdapter(["Year 1","Year 2","Year 3"]).compareLevels("Year 1","Year 3")).toBeLessThan(0);});});

describe("jurisdiction overlays",()=>{it("resolves additions and replacements without mutating the base",()=>{const base=[{stableId:"base.a",title:"Base A"},{stableId:"base.b",title:"Base B"}];const result=applyOverlay(base,[{kind:"replace",targetStableId:"base.b",requirement:{stableId:"state.b",title:"State B",jurisdiction:"US-TX"},reason:"state adoption"},{kind:"add",requirement:{stableId:"state.c",title:"State C",jurisdiction:"US-TX"},reason:"state addition"}]);expect(base.map(x=>x.stableId)).toEqual(["base.a","base.b"]);expect(result.requirements.map(x=>x.stableId)).toEqual(["base.a","state.b","state.c"]);expect(result.conflicts).toEqual([]);});});

describe("committed fixtures",()=>{it.each(["us-architecture-fixture.json","interoperability-fixture.json"])("validates %s",file=>{const document=JSON.parse(readFileSync(new URL(`../fixtures/curriculum/${file}`,import.meta.url),"utf8"));const result=validatePackage(document);expect(result.issues).toEqual([]);expect(result.valid).toBe(true);expect(document.package.provenance.authoritative).toBe(false);});});
