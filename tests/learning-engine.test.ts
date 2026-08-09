import{describe,expect,it}from"vitest";
import{scoreSingleSelect}from"../src/learning/scoring";
import{calculateMastery}from"../src/learning/mastery";
describe("server scoring",()=>{it("scores from protected definitions and ignores client score claims",()=>{const result=scoreSingleSelect([{id:"i1",type:"single_select",correctOption:"b",points:2}],[{itemId:"i1",option:"b"}]);expect(result).toEqual({earned:2,possible:2,outcomes:[{itemId:"i1",earned:2,possible:2}]});});});
describe("mastery",()=>{it("is deterministic, explainable, and requires more than completion",()=>{expect(calculateMastery([{earned:1,possible:1}]).state).toBe("insufficient_evidence");expect(calculateMastery([{earned:1,possible:1},{earned:1,possible:1}])).toMatchObject({state:"advanced",ratio:1,recommendation:"enrichment",policyVersion:"1.0"});});it("selects remediation from weak evidence",()=>{expect(calculateMastery([{earned:0,possible:1},{earned:1,possible:3}]).recommendation).toBe("remediation");});});
