# Requirements: Narrative Node Generator - AI Integration

**Defined:** 2026-01-25
**Core Value:** Generate complete, high-quality narrative nodes with minimal manual effort through AI-powered content creation

## v1 Requirements

### Streaming Generation

- [ ] **STREAM-01**: User sees real-time SSE progress updates during generation (beat-by-beat)
- [ ] **STREAM-02**: User can preview generated content before saving to database
- [ ] **STREAM-03**: User can regenerate content if output quality is unsatisfactory
- [ ] **STREAM-04**: User can cancel in-flight generation requests mid-stream

### Generation Modes

- [ ] **GEN-01**: User can generate single fields (narrative hook, individual beats) via AI
- [ ] **GEN-02**: User can generate complete node from minimal input (type + biome)
- [ ] **GEN-03**: Generated content follows 3-stage pipeline (beat outliner → prose expander → critic)
- [ ] **GEN-04**: User receives error messages with actionable guidance when generation fails

### Quality Control

- [ ] **QUAL-01**: System validates generated JSON structure and required fields
- [ ] **QUAL-02**: Critic LLM scores generated content (0-100 quality rating)
- [ ] **QUAL-03**: System auto-retries generation if critic score falls below threshold
- [ ] **QUAL-04**: User sees critic score breakdown with quality feedback

### Provider Management

- [ ] **PROV-01**: User can add LLM provider configuration (OpenRouter, Anthropic, OpenAI)
- [ ] **PROV-02**: User can edit existing provider settings (model, temperature, max retries)
- [ ] **PROV-03**: User can delete unused providers
- [ ] **PROV-04**: User can activate/deactivate providers
- [ ] **PROV-05**: System stores API keys encrypted in database
- [ ] **PROV-06**: User can configure temperature and model per provider
- [ ] **PROV-07**: System supports environment variable override for API keys (production safety)

### Integration (Wiring Existing Components)

- [ ] **INTG-01**: SSE streaming endpoint connects to frontend EventSource client
- [ ] **INTG-02**: Generation service stages (outliner/expander/critic) wire into API routes
- [ ] **INTG-03**: Prompt builder integrates with generation pipeline
- [ ] **INTG-04**: Batch processor connects to job tracking with progress callbacks
- [ ] **INTG-05**: LLM client supports all configured providers (OpenRouter/Anthropic/OpenAI)

### Configuration Management

- [ ] **CONF-01**: User can view beat roles, sequences, and style guides
- [ ] **CONF-02**: User can edit beat sequences for each node type
- [ ] **CONF-03**: User can edit style guides per biome (atmosphere, sensory details, antipatterns)
- [ ] **CONF-04**: User can manage vernacular glossary (historical terms)
- [ ] **CONF-05**: System loads configuration from database (not hardcoded constants)

### Error Handling & Reliability

- [ ] **ERR-01**: System implements circuit breaker for repeated LLM failures
- [ ] **ERR-02**: System implements exponential backoff retry for transient errors (429, 503)
- [ ] **ERR-03**: SSE connections implement heartbeat to detect dropped connections
- [ ] **ERR-04**: System persists generation jobs to survive connection drops
- [ ] **ERR-05**: User can reconnect to in-progress generation after connection loss

## v2 Requirements

### Advanced Generation Features

- **GEN-A1**: Field-level AI assist buttons in manual form creation
- **GEN-A2**: Bulk generation to automatically fill distribution gaps
- **GEN-A3**: Context-aware suggestions based on existing node content
- **GEN-A4**: Generation presets with saved configurations

### Enhanced Quality & Tracking

- **QUAL-A1**: Quality trend tracking across generated nodes
- **QUAL-A2**: Per-node-type critic score calibration
- **QUAL-A3**: Generation history with rollback capability

### Provider Enhancements

- **PROV-A1**: Provider health checks and connection testing
- **PROV-A2**: Per-provider cost tracking and budgets
- **PROV-A3**: Rate limit monitoring and adaptive concurrency

### Testing Infrastructure

- **TEST-A1**: Unit tests for generation service components
- **TEST-A2**: Integration tests for API routes
- **TEST-A3**: E2E test for single-node generation flow

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multi-user authentication | Single-user local development only |
| Production deployment features | Local environment, no cloud deployment |
| Real-time collaboration | Single-user workflow sufficient |
| Mobile responsiveness | Desktop-first development focus |
| OAuth provider login | API key authentication sufficient |
| WebSocket streaming | SSE simpler for unidirectional streaming |
| Redis/BullMQ job queue | In-memory p-queue sufficient for local use |
| Content versioning | Not needed for v1, defer to future |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| STREAM-01 | Phase 4 | Complete |
| STREAM-02 | Phase 5 | Pending |
| STREAM-03 | Phase 5 | Pending |
| STREAM-04 | Phase 5 | Pending |
| GEN-01 | Phase 6 | Pending |
| GEN-02 | Phase 5 | Pending |
| GEN-03 | Phase 2 | Complete |
| GEN-04 | Phase 2 | Complete |
| QUAL-01 | Phase 3 | Complete |
| QUAL-02 | Phase 3 | Complete |
| QUAL-03 | Phase 3 | Complete |
| QUAL-04 | Phase 3 | Complete |
| PROV-01 | Phase 8 | Pending |
| PROV-02 | Phase 8 | Pending |
| PROV-03 | Phase 8 | Pending |
| PROV-04 | Phase 8 | Pending |
| PROV-05 | Phase 8 | Pending |
| PROV-06 | Phase 8 | Pending |
| PROV-07 | Phase 8 | Pending |
| INTG-01 | Phase 1 | Complete |
| INTG-02 | Phase 2 | Complete |
| INTG-03 | Phase 2 | Complete |
| INTG-04 | Phase 7 | Pending |
| INTG-05 | Phase 2 | Complete |
| CONF-01 | Phase 9 | Pending |
| CONF-02 | Phase 9 | Pending |
| CONF-03 | Phase 9 | Pending |
| CONF-04 | Phase 9 | Pending |
| CONF-05 | Phase 9 | Pending |
| ERR-01 | Phase 2 | Complete |
| ERR-02 | Phase 2 | Complete |
| ERR-03 | Phase 1 | Complete |
| ERR-04 | Phase 1 | Complete |
| ERR-05 | Phase 4 | Complete |

**Coverage:**
- v1 requirements: 34 total
- Mapped to phases: 34/34 ✓
- Unmapped: 0

---
*Requirements defined: 2026-01-25*
*Last updated: 2026-01-25 after roadmap creation*
