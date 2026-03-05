# Phase 2 — Authoring Core Extraction (Draft)

## Goal
Extract shared Atlas primitives into `packages/authoring-core` so Forge can reuse them without duplication.

## Candidates (Frontend)
- GenerationProgress UI
- BulkGenerate UI
- DistributionGapChart
- shared hooks (useGeneration/useConfig/useNodes)

## Candidates (Backend)
- CRUD router factory
- lookup/config routes
- generation settings / batch utilities

## Success Criteria
- Atlas runs unchanged while consuming shared core
- Forge can import the same core
