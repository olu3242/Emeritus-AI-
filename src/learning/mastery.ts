export type MasteryState="not_assessed"|"insufficient_evidence"|"emerging"|"developing"|"proficient"|"advanced";
export interface EvidenceInput { earned:number; possible:number; difficulty?:number; }
export interface MasteryDecision { state:MasteryState; ratio:number; explanation:string; policyVersion:"1.0"; recommendation:"remediation"|"enrichment"|"more_evidence"; }

export function calculateMastery(evidence:EvidenceInput[]):MasteryDecision{
  const possible=evidence.reduce((sum,item)=>sum+item.possible,0); const earned=evidence.reduce((sum,item)=>sum+item.earned,0);
  if(!evidence.length||possible<=0)return{state:"not_assessed",ratio:0,explanation:"No scorable evidence is available.",policyVersion:"1.0",recommendation:"more_evidence"};
  const ratio=Math.round((earned/possible)*10000)/10000;
  const state:MasteryState=evidence.length<2?"insufficient_evidence":ratio>=.9?"advanced":ratio>=.75?"proficient":ratio>=.5?"developing":"emerging";
  const recommendation=state==="advanced"||state==="proficient"?"enrichment":state==="insufficient_evidence"?"more_evidence":"remediation";
  return{state,ratio,explanation:`${earned} of ${possible} weighted points across ${evidence.length} evidence items.`,policyVersion:"1.0",recommendation};
}
