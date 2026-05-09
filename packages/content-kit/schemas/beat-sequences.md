# Beat Sequences Schema

Reusable beat templates. See `rules/beat-sequences.md` for selection logic and examples.

## BeatRoleRecord

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| id          | int    | ✓ | |
| key         | string | ✓ | 1–50 chars; e.g. "setup" |
| displayName | string | ✓ | 1–100 chars |
| description | string \| null |   | |
| isCore      | boolean| ✓ | core role vs extended |
| sortOrder   | int    | ✓ | |
| createdAt   | date   | ✓ | |

## BeatTemplate (element of a sequence)

| Field | Type | Required |
|-------|------|:-------:|
| role     | string  | ✓ | references BeatRoleRecord.key |
| intent   | string  | ✓ | what this beat accomplishes |
| required | boolean | ✓ | default true |

## BeatSequenceRecord

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| id              | int                            | ✓ | |
| nodeType        | NodeType                       | ✓ | |
| sequenceKey     | string                         | ✓ | 1–100 chars; unique selector |
| beatStructure   | BeatTemplate[]                 | ✓ | JSONB |
| weight          | int (1..10)                    | ✓ | selection bias |
| actConstraints  | `{ acts: int[1..4][] }` \| null |   | null = any act |
| requiredTags    | string[]                       | ✓ | JSONB; subset of node tags required |
| createdAt       | date                           | ✓ | |
| updatedAt       | date                           | ✓ | |

## Built-in beat roles

See `rules/beat-sequences.md` for the catalog. Core: setup, escalation, reveal, choice, consequence, button. Extended: tension, relief, foreshadow, reflection.
