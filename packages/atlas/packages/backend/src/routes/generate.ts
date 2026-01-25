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
 * Parameters for saving a node to the database
 */
interface SaveNodeParams {
  nodeId?: string;
  nodeType: string;
  biome: string;
  name: string;
  acts?: number[];
  actVariant?: boolean;
  themes: string[];
  entityTypes: string[];
  content: any; // ExpandedContent from generation
  criticScore?: number;
  estimatedCombatDifficulty?: number;
  // Type-specific fields from request
  enemyTypeHooks?: string[];
  environmentalContext?: string;
  consequenceHooks?: string[];
  dilemmaType?: string;
  traderArchetype?: string;
  pricingHooks?: string[];
  restType?: string;
  interruptionChance?: 'none' | 'low' | 'medium' | 'high';
  dreamHooks?: string[];
  travelEventHooks?: string[];
  environmentalStorytelling?: string;
  conditionHooks?: string[];
  actChangeTrigger?: number;
  narrativeSummary?: string;
  worldStateShifts?: any;
}

/**
 * Save or update a node in the database
 * @returns The nodeId of the saved node
 */
export async function saveNodeToDatabase(params: SaveNodeParams): Promise<string> {
  const nodeId = params.nodeId || crypto.randomUUID();

  const nodeData = {
    nodeId,
    type: params.nodeType as any,
    biome: params.biome as any,
    name: params.name,
    acts: params.acts || [1],
    actVariant: params.actVariant || false,
    isReplaceable: true,
    replacementTags: [],
    themes: params.themes,
    entityTypes: params.entityTypes,
    estimatedCombatDifficulty: params.estimatedCombatDifficulty,
    eligibility: null,
    resourceCost: null,
    potentialRewards: [],
    content: params.content,
    actVariants: null,
    criticScore: params.criticScore,
    generatedBy: 'ai',
    // Type-specific fields
    enemyTypeHooks: params.enemyTypeHooks,
    environmentalContext: params.environmentalContext,
    consequenceHooks: params.consequenceHooks,
    dilemmaType: params.dilemmaType as any,
    traderArchetype: params.traderArchetype,
    pricingHooks: params.pricingHooks,
    restType: params.restType as any,
    interruptionChance: params.interruptionChance as any,
    dreamHooks: params.dreamHooks,
    travelEventHooks: params.travelEventHooks,
    environmentalStorytelling: params.environmentalStorytelling,
    conditionHooks: params.conditionHooks,
    actChangeTrigger: params.actChangeTrigger as any,
    narrativeSummary: params.narrativeSummary,
    worldStateShifts: params.worldStateShifts,
  };

  if (params.nodeId) {
    // Update existing node
    await db.update(nodesTable).set(nodeData as any).where(eq(nodesTable.nodeId, params.nodeId));
  } else {
    // Insert new node
    await db.insert(nodesTable).values(nodeData as any);
  }

  return nodeId;
}

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
    if (result.content) {
      const savedNodeId = await saveNodeToDatabase({
        nodeId: request.nodeId,
        nodeType: request.nodeType,
        biome: request.biome,
        name: request.name,
        acts: request.acts,
        actVariant: request.actVariant,
        themes: request.themes,
        entityTypes: request.entityTypes,
        content: result.content,
        criticScore: result.critic?.score,
        estimatedCombatDifficulty: request.estimatedCombatDifficulty,
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
      });
      result.nodeId = savedNodeId;
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
