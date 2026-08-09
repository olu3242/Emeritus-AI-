export interface SingleSelectItem { id:string; type:"single_select"; correctOption:string; points:number; }
export interface LearnerAnswer { itemId:string; option:string; }
export interface ScoreResult { earned:number; possible:number; outcomes:Array<{itemId:string;earned:number;possible:number}>; }
export function scoreSingleSelect(items:SingleSelectItem[],answers:LearnerAnswer[]):ScoreResult{
  const answerMap=new Map(answers.map(answer=>[answer.itemId,answer.option]));
  const outcomes=items.map(item=>({itemId:item.id,earned:answerMap.get(item.id)===item.correctOption?item.points:0,possible:item.points}));
  return{earned:outcomes.reduce((s,o)=>s+o.earned,0),possible:outcomes.reduce((s,o)=>s+o.possible,0),outcomes};
}
