import { createHash } from "node:crypto";
import { z } from "zod";
import type { CurriculumPackageDocument, ImportIssue, ImportPlan } from "./types";
import { nodeKinds, relationshipKinds } from "./types";

const provenanceSchema = z.object({
  sourceUrl: z.string().url(), sourceTitle: z.string().min(1), publisher: z.string().min(1),
  licenseId: z.string().min(1), licenseUrl: z.string().url().optional(),
  retrievedAt: z.string().datetime(), authoritative: z.boolean(),
});
const documentSchema = z.object({
  schemaVersion: z.literal("1.0"),
  package: z.object({
    stableId: z.string().regex(/^[a-z0-9][a-z0-9._:-]+$/), title: z.string().min(1),
    authorityStableId: z.string().min(1), countryCode: z.string().length(2),
    jurisdictionCode: z.string().optional(), version: z.string().min(1),
    effectiveFrom: z.string().date(), effectiveTo: z.string().date().optional(),
    terminology: z.record(z.string()).optional(), policies: z.record(z.unknown()).optional(),
    provenance: provenanceSchema,
  }),
  nodes: z.array(z.object({
    stableId: z.string().min(1), kind: z.enum(nodeKinds), code: z.string().optional(),
    title: z.string().min(1), description: z.string().optional(), level: z.string().optional(),
    subject: z.string().optional(), jurisdiction: z.string().optional(),
    metadata: z.record(z.unknown()).optional(), provenance: provenanceSchema,
  })).max(5000),
  relationships: z.array(z.object({
    stableId: z.string().min(1), fromStableId: z.string().min(1), toStableId: z.string().min(1),
    kind: z.enum(relationshipKinds), metadata: z.record(z.unknown()).optional(),
  })).max(10000),
});

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value && typeof value === "object") return `{${Object.entries(value).sort(([a], [b]) => a.localeCompare(b)).map(([k, v]) => `${JSON.stringify(k)}:${canonical(v)}`).join(",")}}`;
  return JSON.stringify(value);
}

export function validatePackage(input: unknown): ImportPlan {
  const parsed = documentSchema.safeParse(input);
  if (!parsed.success) {
    const issues: ImportIssue[] = parsed.error.issues.map(i => ({ path: i.path.join("."), code: i.code, message: i.message, severity: "error" }));
    return { valid: false, digest: "", creates: 0, changes: 0, unchanged: 0, issues, document: input as CurriculumPackageDocument };
  }
  const doc = parsed.data as CurriculumPackageDocument;
  const issues: ImportIssue[] = [];
  const ids = new Set<string>();
  for (const [index, node] of doc.nodes.entries()) {
    if (ids.has(node.stableId)) issues.push({ path: `nodes.${index}.stableId`, code: "duplicate", message: `Duplicate node ${node.stableId}`, severity: "error" });
    ids.add(node.stableId);
    if (!node.provenance.licenseId) issues.push({ path: `nodes.${index}.provenance`, code: "license_missing", message: "License is required", severity: "error" });
  }
  const edgeIds = new Set<string>();
  for (const [index, edge] of doc.relationships.entries()) {
    if (edgeIds.has(edge.stableId)) issues.push({ path: `relationships.${index}.stableId`, code: "duplicate", message: `Duplicate relationship ${edge.stableId}`, severity: "error" });
    edgeIds.add(edge.stableId);
    if (!ids.has(edge.fromStableId) || !ids.has(edge.toStableId)) issues.push({ path: `relationships.${index}`, code: "unknown_endpoint", message: "Relationship endpoint is absent from this package", severity: "error" });
    if (edge.fromStableId === edge.toStableId) issues.push({ path: `relationships.${index}`, code: "self_reference", message: "Self relationships are not allowed", severity: "error" });
  }
  const digest = createHash("sha256").update(canonical(doc)).digest("hex");
  return { valid: !issues.some(i => i.severity === "error"), digest, creates: doc.nodes.length + doc.relationships.length, changes: 0, unchanged: 0, issues, document: doc };
}
