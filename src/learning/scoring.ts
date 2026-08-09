export interface SingleSelectItem { id:string; type:"single_select"; correctOption:string; points:number; }
export interface LearnerAnswer { itemId:string; option:string; }
export interface ScoreResult { earned:number; possible:number; outcomes:Array<{itemId:string;earned:number;possible:number}>; }
export function scoreSingleSelect(items:SingleSelectItem[],answers:LearnerAnswer[]):ScoreResult{
  const answerMap=new Map(answers.map(answer=>[answer.itemId,answer.option]));
  const outcomes=items.map(item=>({itemId:item.id,earned:answerMap.get(item.id)===item.correctOption?item.points:0,possible:item.points}));
  return{earned:outcomes.reduce((s,o)=>s+o.earned,0),possible:outcomes.reduce((s,o)=>s+o.possible,0),outcomes};
}

export type AutoItem=
 |SingleSelectItem
 |{id:string;type:"multi_select";correctOptions:string[];points:number}
 |{id:string;type:"numeric_response";correct:number;tolerance:number;points:number}
 |{id:string;type:"short_response";accepted:string[];points:number};
export type CanonicalAnswer={itemId:string;option?:string;options?:string[];number?:number;text?:string};
export function scoreAutomatic(items:AutoItem[],answers:CanonicalAnswer[]):ScoreResult{const responses=new Map(answers.map(answer=>[answer.itemId,answer]));const outcomes=items.map(item=>{const answer=responses.get(item.id);let correct=false;if(item.type==="single_select")correct=answer?.option===item.correctOption;if(item.type==="multi_select")correct=JSON.stringify([...(answer?.options??[])].sort())===JSON.stringify([...item.correctOptions].sort());if(item.type==="numeric_response")correct=typeof answer?.number==="number"&&Math.abs(answer.number-item.correct)<=item.tolerance;if(item.type==="short_response")correct=item.accepted.map(value=>value.trim().toLocaleLowerCase()).includes(answer?.text?.trim().toLocaleLowerCase()??"");return{itemId:item.id,earned:correct?item.points:0,possible:item.points};});return{earned:outcomes.reduce((sum,item)=>sum+item.earned,0),possible:outcomes.reduce((sum,item)=>sum+item.possible,0),outcomes};}
