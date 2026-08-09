import{BaseSequencer,type WorkspaceSpec}from"vitest/node";
export default class IntegrationSequencer extends BaseSequencer{async sort(files:WorkspaceSpec[]){return[...files].sort((a,b)=>a.moduleId.localeCompare(b.moduleId));}}
