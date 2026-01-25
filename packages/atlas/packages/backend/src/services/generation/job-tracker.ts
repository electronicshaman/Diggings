/**
 * Job Tracker - Manages generation job lifecycle and persistence
 * Handles job creation, status updates, retrieval, and cleanup
 */

import { db } from '../../db/index.js';
import { generationJobs } from '../../db/schema.js';
import { eq, lt } from 'drizzle-orm';
import { randomUUID } from 'crypto';

export type JobStatus = 'pending' | 'running' | 'completed' | 'failed';

export interface JobUpdate {
  status?: JobStatus;
  progress?: number;
  currentStage?: string;
  result?: any;
  error?: string;
}

/**
 * Create a new generation job
 */
export async function createJob(params: {
  nodeType: string;
  biome: string;
  request: any;
}): Promise<{ jobId: string; id: number }> {
  const jobId = randomUUID();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours from now

  const result = await db
    .insert(generationJobs)
    .values({
      jobId,
      status: 'pending',
      nodeType: params.nodeType as any,
      biome: params.biome as any,
      request: params.request,
      progress: 0,
      currentStage: null,
      result: null,
      error: null,
      expiresAt,
    })
    .returning({ id: generationJobs.id, jobId: generationJobs.jobId });

  return result[0];
}

/**
 * Update job status and progress
 */
export async function updateJobStatus(jobId: string, updates: JobUpdate): Promise<void> {
  const updateData: any = {
    updatedAt: new Date(),
  };

  if (updates.status !== undefined) {
    updateData.status = updates.status;
  }
  if (updates.progress !== undefined) {
    updateData.progress = updates.progress;
  }
  if (updates.currentStage !== undefined) {
    updateData.currentStage = updates.currentStage;
  }
  if (updates.result !== undefined) {
    updateData.result = updates.result;
  }
  if (updates.error !== undefined) {
    updateData.error = updates.error;
  }

  await db.update(generationJobs).set(updateData).where(eq(generationJobs.jobId, jobId));
}

/**
 * Get job by ID
 */
export async function getJob(jobId: string) {
  const results = await db.select().from(generationJobs).where(eq(generationJobs.jobId, jobId));

  if (results.length === 0) {
    return null;
  }

  return results[0];
}

/**
 * Clean up expired jobs
 */
export async function cleanupOldJobs(): Promise<number> {
  const now = new Date();
  const result = await db.delete(generationJobs).where(lt(generationJobs.expiresAt, now));

  // Drizzle doesn't return rowCount, so we'll need to count before delete
  // For now, return 0 as this is not critical for the MVP
  return 0;
}
