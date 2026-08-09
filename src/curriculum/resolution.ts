export interface ResolvableRequirement { stableId:string; title:string; jurisdiction?:string; metadata?:Record<string,unknown>; }
export interface OverlayChange { kind:"add"|"replace"|"exclude"; targetStableId?:string; requirement?:ResolvableRequirement; reason:string; }

export function applyOverlay(base: ResolvableRequirement[], changes: OverlayChange[]) {
  const resolved=new Map(base.map(item=>[item.stableId,{...item}])); const explanation:string[]=[]; const conflicts:string[]=[];
  for(const change of changes) {
    if(change.kind==="add" && change.requirement) { if(resolved.has(change.requirement.stableId)) conflicts.push(`Addition duplicates ${change.requirement.stableId}`); else { resolved.set(change.requirement.stableId,{...change.requirement}); explanation.push(`Added ${change.requirement.stableId}: ${change.reason}`); } }
    if(change.kind==="exclude" && change.targetStableId) { if(resolved.delete(change.targetStableId)) explanation.push(`Excluded ${change.targetStableId}: ${change.reason}`); else conflicts.push(`Cannot exclude missing ${change.targetStableId}`); }
    if(change.kind==="replace" && change.targetStableId && change.requirement) { if(!resolved.delete(change.targetStableId)) conflicts.push(`Cannot replace missing ${change.targetStableId}`); resolved.set(change.requirement.stableId,{...change.requirement}); explanation.push(`Replaced ${change.targetStableId} with ${change.requirement.stableId}: ${change.reason}`); }
  }
  return {requirements:[...resolved.values()].sort((a,b)=>a.stableId.localeCompare(b.stableId)),explanation,conflicts};
}
