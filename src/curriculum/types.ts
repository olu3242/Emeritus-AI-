export const workflowStates = [
  "draft", "automated_validation", "curriculum_review", "accessibility_review",
  "approved", "published", "superseded", "archived",
] as const;
export type WorkflowState = (typeof workflowStates)[number];

export const nodeKinds = [
  "stage", "level", "subject", "program", "course", "strand", "domain", "unit",
  "topic", "standard", "competency", "outcome", "objective",
] as const;
export type NodeKind = (typeof nodeKinds)[number];

export const relationshipKinds = [
  "contains", "prerequisite", "progresses_to", "aligns_to", "replaces", "excludes",
] as const;
export type RelationshipKind = (typeof relationshipKinds)[number];

export interface Provenance {
  sourceUrl: string;
  sourceTitle: string;
  publisher: string;
  licenseId: string;
  licenseUrl?: string;
  retrievedAt: string;
  authoritative: boolean;
}

export interface CurriculumNodeInput {
  stableId: string;
  kind: NodeKind;
  code?: string;
  title: string;
  description?: string;
  level?: string;
  subject?: string;
  jurisdiction?: string;
  metadata?: Record<string, unknown>;
  provenance: Provenance;
}

export interface CurriculumRelationshipInput {
  stableId: string;
  fromStableId: string;
  toStableId: string;
  kind: RelationshipKind;
  metadata?: Record<string, unknown>;
}

export interface CurriculumPackageDocument {
  schemaVersion: "1.0";
  package: {
    stableId: string;
    title: string;
    authorityStableId: string;
    countryCode: string;
    jurisdictionCode?: string;
    version: string;
    effectiveFrom: string;
    effectiveTo?: string;
    terminology?: Record<string, string>;
    policies?: Record<string, unknown>;
    provenance: Provenance;
  };
  nodes: CurriculumNodeInput[];
  relationships: CurriculumRelationshipInput[];
}

export interface ImportIssue {
  path: string;
  code: string;
  message: string;
  severity: "error" | "warning";
}

export interface ImportPlan {
  valid: boolean;
  digest: string;
  creates: number;
  changes: number;
  unchanged: number;
  issues: ImportIssue[];
  document: CurriculumPackageDocument;
}

export interface ResolutionResult {
  packageVersionId: string;
  requirements: Array<Record<string, unknown>>;
  prerequisites: Array<Record<string, unknown>>;
  policies: Record<string, unknown>;
  provenance: Provenance[];
  explanation: string[];
  gaps: string[];
  conflicts: string[];
}
