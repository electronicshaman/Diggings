#!/usr/bin/env bun
/**
 * Import CLI-generated nodes into Atlas
 * Usage: bun run src/db/import-cli-nodes.ts <nodes-directory>
 * 
 * Example: bun run src/db/import-cli-nodes.ts /Users/rob/Projects/graph-grammar-generator/nodes-improved
 */

import { db, nodes } from './index.js';
import { AnyNodeMetadataSchema } from '@node-gen-web/shared';
import { eq } from 'drizzle-orm';

const args = process.argv.slice(2);
if (args.length < 1) {
  console.error('Usage: bun run src/db/import-cli-nodes.ts <nodes-directory>');
  process.exit(1);
}

const nodesDir = args[0];

async function importNodes() {
  console.log(`Importing nodes from: ${nodesDir}`);
  
  // Use ls to list all .json files in the directory
  const lsProcess = Bun.spawn(['ls', '-1', nodesDir]);
  const output = await new Response(lsProcess.stdout).text();
  const jsonFiles = output.trim().split('\n').filter(f => f.endsWith('.json'));
  
  console.log(`Found ${jsonFiles.length} JSON files`);

  let imported = 0;
  let skipped = 0;
  let errors: string[] = [];

  for (const file of jsonFiles) {
    const filePath = `${nodesDir}/${file}`;
    const content = await Bun.file(filePath).text();
    
    try {
      const nodeData = JSON.parse(content);
      
      // Validate against schema
      const parseResult = AnyNodeMetadataSchema.safeParse(nodeData);
      
      if (!parseResult.success) {
        console.warn(`Skipping ${file}: validation failed`);
        console.warn(parseResult.error.issues.slice(0, 3));
        skipped++;
        continue;
      }

      const data = parseResult.data;

      // Check if node already exists
      const existing = await db
        .select()
        .from(nodes)
        .where(eq(nodes.nodeId, data.id))
        .limit(1);

      if (existing.length > 0) {
        console.log(`Skipping ${data.id}: already exists`);
        skipped++;
        continue;
      }

      // Transform to database schema
      const dbData = transformToDb(data);

      // Insert
      await db.insert(nodes).values(dbData);
      console.log(`Imported: ${data.id} (${data.type} in ${data.biome})`);
      imported++;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      errors.push(`${file}: ${msg}`);
      console.error(`Error processing ${file}:`, msg);
    }
  }

  console.log('\n--- Import Summary ---');
  console.log(`Imported: ${imported}`);
  console.log(`Skipped: ${skipped}`);
  console.log(`Errors: ${errors.length}`);
  
  if (errors.length > 0) {
    console.log('\nErrors:');
    errors.forEach(e => console.log(`  - ${e}`));
  }

  process.exit(errors.length > 0 ? 1 : 0);
}

function transformToDb(data: any): any {
  const dbData: any = {
    nodeId: data.id,
    type: data.type,
    biome: data.biome,
    name: data.name,
    acts: data.acts,
    actVariant: data.actVariant || false,
    isReplaceable: data.isReplaceable ?? true,
    replacementTags: data.replacementTags || [],
    themes: data.themes || [],
    entityTypes: data.entityTypes || [],
    eligibility: data.eligibility || null,
    estimatedCombatDifficulty: data.estimatedCombatDifficulty || null,
    resourceCost: data.resourceCost || null,
    potentialRewards: data.potentialRewards || null,
    content: data.content || null,
    actVariants: data.actVariants || null,
  };

  // Type-specific fields
  if (data.type === 'combat') {
    dbData.enemyTypeHooks = data.enemyTypeHooks || [];
    dbData.environmentalContext = data.environmentalContext || null;
  } else if (data.type === 'choice') {
    dbData.consequenceHooks = data.consequenceHooks || [];
    dbData.dilemmaType = data.dilemmaType || null;
  } else if (data.type === 'trade') {
    dbData.traderArchetype = data.traderArchetype || null;
    dbData.pricingHooks = data.pricingHooks || [];
  } else if (data.type === 'rest') {
    dbData.restType = data.restType || null;
    dbData.interruptionChance = data.interruptionChance || null;
    dbData.dreamHooks = data.dreamHooks || [];
  } else if (data.type === 'passage') {
    dbData.travelEventHooks = data.travelEventHooks || [];
    dbData.environmentalStorytelling = data.environmentalStorytelling || [];
  } else if (data.type === 'state_check') {
    dbData.conditionHooks = data.conditionHooks || [];
    dbData.branchTargets = data.branchTargets || [];
  } else if (data.type === 'transition') {
    dbData.actChangeTrigger = data.actChangeTrigger || null;
    dbData.narrativeSummary = data.narrativeSummary || null;
    dbData.worldStateShifts = data.worldStateShifts || [];
  }

  return dbData;
}

importNodes();
