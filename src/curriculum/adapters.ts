import type { CurriculumPackageDocument, CurriculumNodeInput } from "./types";

export interface StructureAdapter<T> { adapt(input: T): CurriculumPackageDocument; }
export interface TerminologyAdapter { label(canonicalTerm: string, terminology: Record<string, string>): string; }
export interface StandardsAdapter<T> { nodes(input: T): CurriculumNodeInput[]; }
export interface JurisdictionAdapter { overlayKey(country: string, jurisdiction?: string): string | undefined; }
export interface ProgressionAdapter { compareLevels(left: string, right: string): number; }
export interface AssessmentPolicyAdapter { normalize(policy: unknown): Record<string, unknown>; }
export interface CalendarAdapter { academicYear(at: Date): string; }
export interface LocalizationAdapter { locale(country: string, jurisdiction?: string): string; }

export class ConfigurableTerminologyAdapter implements TerminologyAdapter {
  label(canonicalTerm: string, terminology: Record<string, string>): string { return terminology[canonicalTerm] ?? canonicalTerm; }
}

export class OrderedProgressionAdapter implements ProgressionAdapter {
  constructor(private readonly levels: string[]) {}
  compareLevels(left: string, right: string): number { return this.levels.indexOf(left) - this.levels.indexOf(right); }
}

function splitCsvLine(line: string): string[] {
  const values: string[] = []; let current = ""; let quoted = false;
  for (let i=0;i<line.length;i++) { const c=line[i]; if(c==='"' && line[i+1]==='"' && quoted){current+='"';i++;} else if(c==='"'){quoted=!quoted;} else if(c===','&&!quoted){values.push(current);current="";} else current+=c; }
  values.push(current); return values;
}

export function parseCurriculumCsv(csv: string, shell: CurriculumPackageDocument["package"]): CurriculumPackageDocument {
  const lines=csv.replace(/^\uFEFF/,"").split(/\r?\n/).filter(Boolean); if(lines.length<2) throw new Error("CSV requires a header and record");
  const header=splitCsvLine(lines[0]); const required=["stableId","kind","title","sourceUrl","sourceTitle","publisher","licenseId","retrievedAt","authoritative"];
  for(const name of required) if(!header.includes(name)) throw new Error(`Missing CSV column ${name}`);
  const nodes=lines.slice(1).map((line,row) => { const cells=splitCsvLine(line); const value=(name:string)=>cells[header.indexOf(name)]??"";
    if(cells.length!==header.length) throw new Error(`CSV row ${row+2} has ${cells.length} columns; expected ${header.length}`);
    return { stableId:value("stableId"),kind:value("kind") as CurriculumNodeInput["kind"],code:value("code")||undefined,title:value("title"),description:value("description")||undefined,level:value("level")||undefined,subject:value("subject")||undefined,jurisdiction:value("jurisdiction")||undefined,provenance:{sourceUrl:value("sourceUrl"),sourceTitle:value("sourceTitle"),publisher:value("publisher"),licenseId:value("licenseId"),licenseUrl:value("licenseUrl")||undefined,retrievedAt:value("retrievedAt"),authoritative:value("authoritative").toLowerCase()==="true"}};
  });
  return { schemaVersion:"1.0",package:shell,nodes,relationships:[] };
}
