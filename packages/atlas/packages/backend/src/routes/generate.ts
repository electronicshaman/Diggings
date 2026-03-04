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
  type GenerationProgress,
} from '../services/generation/index.js';
import { db } from '../db/index.js';
import { nodes as nodesTable, distributions } from '../db/schema.js';
import { eq, sql } from 'drizzle-orm';

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
 * Analyze distribution gaps and build generation requests
 */
async function buildBulkRequests(request: BulkGenerationRequest): Promise<NodeGenerationRequest[]> {
  const requests: NodeGenerationRequest[] = [];

  if (request.fillGaps) {
    // Get target distributions
    const targetDists = await db.select().from(distributions);

    // Get actual node counts grouped by biome and type
    const actualCounts = await db
      .select({
        biome: nodesTable.biome,
        nodeType: nodesTable.type,
        count: sql<number>`count(*)::int`,
      })
      .from(nodesTable)
      .groupBy(nodesTable.biome, nodesTable.type);

    const actualMap = new Map<string, number>();
    for (const row of actualCounts) {
      actualMap.set(`${row.biome}_${row.nodeType}`, row.count);
    }

    // Build requests for each gap
    for (const target of targetDists) {
      // Apply filters if specified
      if (request.biome && target.biome !== request.biome) continue;
      if (request.nodeType && target.nodeType !== request.nodeType) continue;

      const actual = actualMap.get(`${target.biome}_${target.nodeType}`) || 0;
      const gap = target.count - actual;

      if (gap <= 0) continue;

      const count = request.count ? Math.min(gap, request.count) : gap;
      for (let i = 0; i < count; i++) {
        requests.push({
          nodeId: crypto.randomUUID(),
          nodeType: target.nodeType,
          biome: target.biome,
          name: `${target.biome} ${target.nodeType} ${actual + i + 1}`,
          themes: [],
          entityTypes: [],
          act: 1,
          nodeMetadata: {},
        });
      }
    }
  } else {
    // Manual mode: generate specific biome/type combo
    const count = request.count || 5;
    const biome = request.biome || 'township';
    const nodeType = request.nodeType || 'passage';

    for (let i = 0; i < count; i++) {
      requests.push({
        nodeId: crypto.randomUUID(),
        nodeType,
        biome,
        name: `${biome} ${nodeType} ${i + 1}`,
        themes: [],
        entityTypes: [],
        act: 1,
        nodeMetadata: {},
      });
    }
  }

  return requests;
}

/**
 * POST /api/generate/bulk
 * Generate multiple nodes with SSE streaming progress
 */
app.post('/bulk', zValidator('json', BulkGenerationRequestSchema), async (c) => {
  const request = c.req.valid('json') as BulkGenerationRequest;

  try {
    const requests = await buildBulkRequests(request);

    if (requests.length === 0) {
      return c.json({ success: true, message: 'No gaps to fill', total: 0, successful: 0, failed: 0 });
    }

    // Set SSE headers
    c.header('Content-Type', 'text/event-stream');
    c.header('Cache-Control', 'no-cache, no-store, must-revalidate');
    c.header('Connection', 'keep-alive');
    c.header('X-Accel-Buffering', 'no');
    c.header('X-Content-Type-Options', 'nosniff');

    const encoder = new TextEncoder();

    const stream = new ReadableStream({
      async start(controller) {
        const heartbeat = setInterval(() => {
          try {
            controller.enqueue(
              encoder.encode(`event: ping\ndata: ${JSON.stringify({ timestamp: Date.now() })}\n\n`)
            );
          } catch {
            clearInterval(heartbeat);
          }
        }, 12000);

        let completed = 0;
        let failed = 0;

        // Send initial event with total count
        controller.enqueue(
          encoder.encode(
            `event: bulk_start\ndata: ${JSON.stringify({ total: requests.length })}\n\n`
          )
        );

        try {
          const result = await generateBatch(requests, {
            onProgress: (progress: GenerationProgress) => {
              if (progress.stage === 'completed') {
                completed++;
              } else if (progress.stage === 'failed') {
                failed++;
              }

              controller.enqueue(
                encoder.encode(
                  `event: node_progress\ndata: ${JSON.stringify({
                    nodeId: progress.nodeId,
                    stage: progress.stage,
                    progress: progress.progress,
                    completed,
                    failed,
                    total: requests.length,
                    error: progress.error,
                  })}\n\n`
                )
              );
            },
          });

          // Save successful nodes to database
          for (const [nodeId, progress] of result.results) {
            if (progress.stage === 'completed' && progress.content) {
              const req = requests.find((r) => r.nodeId === nodeId);
              if (req) {
                try {
                  await saveNodeToDatabase({
                    nodeId: req.nodeId,
                    nodeType: req.nodeType,
                    biome: req.biome,
                    name: req.name,
                    themes: req.themes,
                    entityTypes: req.entityTypes,
                    content: progress.content,
                    criticScore: progress.critic?.score,
                  });
                } catch (dbError) {
                  console.error(`Failed to save bulk node ${nodeId}:`, dbError);
                }
              }
            }
          }

          // Send completion event
          controller.enqueue(
            encoder.encode(
              `event: bulk_complete\ndata: ${JSON.stringify({
                total: result.total,
                successful: result.successful,
                failed: result.failed,
              })}\n\n`
            )
          );
        } catch (error) {
          controller.enqueue(
            encoder.encode(
              `event: bulk_error\ndata: ${JSON.stringify({
                error: error instanceof Error ? error.message : 'Bulk generation failed',
                completed,
                failed,
                total: requests.length,
              })}\n\n`
            )
          );
        }

        clearInterval(heartbeat);
        controller.close();
      },
    });

    return new Response(stream);
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
