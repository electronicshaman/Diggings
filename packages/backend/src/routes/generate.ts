import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import {
  GenerationRequestSchema,
  BulkGenerationRequestSchema,
  type GenerationRequest,
  type BulkGenerationRequest,
} from '@node-gen-web/shared';
import {
  generateSingle,
  generateBatch,
  streamGeneration,
  createJob,
  getJob,
  type NodeGenerationRequest,
} from '../services/generation/index.js';
import { db } from '../db/index.js';
import { nodes as nodesTable } from '../db/schema.js';
import { eq } from 'drizzle-orm';

const app = new Hono();

/**
 * Convert GenerationRequest to NodeGenerationRequest
 */
function toNodeGenerationRequest(request: GenerationRequest): NodeGenerationRequest {
  return {
    nodeId: request.nodeId || '',
    nodeType: request.nodeType,
    biome: request.biome,
    name: request.name,
    themes: request.themes,
    entityTypes: request.entityTypes,
    act: request.acts?.[0], // Use first act if multiple
    nodeMetadata: {
      // Type-specific fields
      enemyTypeHooks: request.enemyTypeHooks,
      environmentalContext: request.environmentalContext,
      consequenceHooks: request.consequenceHooks,
      dilemmaType: request.dilemmaType,
      traderArchetype: request.traderArchetype,
      pricingHooks: request.pricingHooks,
      restType: request.restType,
      interruptionChance: request.interruptionChance,
      dreamHooks: request.dreamHooks,
      travelEventHooks: request.travelEventHooks,
      environmentalStorytelling: request.environmentalStorytelling,
      conditionHooks: request.conditionHooks,
      actChangeTrigger: request.actChangeTrigger,
      narrativeSummary: request.narrativeSummary,
      worldStateShifts: request.worldStateShifts,
    },
  };
}

/**
 * POST /api/generate/stream
 * Generate a single node with real-time SSE updates
 */
app.post('/stream', zValidator('json', GenerationRequestSchema), async (c) => {
  const request = c.req.valid('json') as GenerationRequest;

  try {
    // Create job first
    const job = await createJob({
      nodeType: request.nodeType,
      biome: request.biome,
      request: request,
    });

    // Convert request format
    const nodeRequest = toNodeGenerationRequest(request);
    nodeRequest.nodeId = job.jobId; // Use job ID as node ID for tracking

    // Stream the generation
    return await streamGeneration(c, nodeRequest, job.jobId);
  } catch (error) {
    console.error('Stream generation error:', error);
    return c.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      },
      500
    );
  }
});

/**
 * GET /api/generate/job/:jobId
 * Get job status by ID (for reconnection support)
 */
app.get('/job/:jobId', async (c) => {
  const jobId = c.req.param('jobId');

  try {
    const job = await getJob(jobId);

    if (!job) {
      return c.json(
        {
          success: false,
          error: 'Job not found',
        },
        404
      );
    }

    return c.json({
      success: true,
      job: {
        jobId: job.jobId,
        status: job.status,
        progress: job.progress,
        currentStage: job.currentStage,
        result: job.result,
        error: job.error,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
      },
    });
  } catch (error) {
    console.error('Job lookup error:', error);
    return c.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      },
      500
    );
  }
});

/**
 * POST /api/generate/node
 * Generate a single node with full 3-stage pipeline (non-streaming)
 */
app.post('/node', zValidator('json', GenerationRequestSchema), async (c) => {
  const request = c.req.valid('json') as GenerationRequest;

  try {
    const nodeRequest = toNodeGenerationRequest(request);
    const result = await generateSingle(nodeRequest);

    if (result.stage === 'failed') {
      return c.json(
        {
          success: false,
          error: result.error || 'Generation failed',
        },
        500
      );
    }

    // Save to database if successful
    if (result.content && result.nodeId) {
      const nodeData = {
        nodeId: result.nodeId,
        type: request.nodeType,
        biome: request.biome,
        name: request.name,
        acts: request.acts,
        actVariant: request.actVariant || false,
        isReplaceable: true,
        replacementTags: [],
        themes: request.themes,
        entityTypes: request.entityTypes,
        estimatedCombatDifficulty: request.estimatedCombatDifficulty,
        eligibility: null,
        resourceCost: null,
        potentialRewards: [],
        content: result.content,
        actVariants: null,
        criticScore: result.critic?.score,
        generatedBy: 'ai',

        // Type-specific fields
        enemyTypeHooks: request.enemyTypeHooks,
        environmentalContext: request.environmentalContext,
        consequenceHooks: request.consequenceHooks,
        dilemmaType: request.dilemmaType,
        traderArchetype: request.traderArchetype,
        pricingHooks: request.pricingHooks,
        restType: request.restType,
        interruptionChance: request.interruptionChance,
        dreamHooks: request.dreamHooks,
        travelEventHooks: request.travelEventHooks,
        environmentalStorytelling: request.environmentalStorytelling,
        conditionHooks: request.conditionHooks,
        actChangeTrigger: request.actChangeTrigger,
        narrativeSummary: request.narrativeSummary,
        worldStateShifts: request.worldStateShifts,
      };

      if (request.nodeId) {
        // Update existing node
        await db.update(nodesTable).set(nodeData).where(eq(nodesTable.nodeId, request.nodeId));
      } else {
        // Insert new node
        await db.insert(nodesTable).values(nodeData as any);
      }
    }

    return c.json({
      success: true,
      nodeId: result.nodeId,
      outline: result.outline,
      content: result.content,
      critic: result.critic,
    });
  } catch (error) {
    console.error('Generation error:', error);
    return c.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      },
      500
    );
  }
});

/**
 * POST /api/generate/bulk
 * Generate multiple nodes based on distribution gaps
 */
app.post('/bulk', zValidator('json', BulkGenerationRequestSchema), async (c) => {
  const request = c.req.valid('json') as BulkGenerationRequest;

  try {
    // TODO: Implement distribution gap analysis to determine what nodes to generate
    // For now, return an error indicating this is not yet implemented
    return c.json(
      {
        success: false,
        error: 'Bulk generation not yet implemented. Use /api/generate/node for single generation.',
      },
      501
    );
  } catch (error) {
    console.error('Bulk generation error:', error);
    return c.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      },
      500
    );
  }
});

/**
 * POST /api/generate/validate
 * Validate content using only the critic stage (no generation)
 */
app.post('/validate', async (c) => {
  // TODO: Implement critic-only validation
  return c.json(
    {
      success: false,
      error: 'Validation endpoint not yet implemented.',
    },
    501
  );
});

export default app;
