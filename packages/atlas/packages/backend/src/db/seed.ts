import { db } from './index.js';
import {
  biomes as biomesTable,
  distributions as distributionsTable,
  enemyTypes,
  environmentalContexts,
  consequenceHooks as consequenceHooksTable,
  dreamHooksTable,
  travelEventHooks,
  environmentalStorytellingTable,
  conditionHooksTable,
  traderArchetypes as traderArchetypesTable,
  pricingHooksTable,
  beatRoles as beatRolesTable,
  beatSequences as beatSequencesTable,
  styleGuide as styleGuideTable,
  vernacular as vernacularTable,
  actTones as actTonesTable,
  generationSettings as generationSettingsTable,
} from './schema.js';
import {
  ALL_BIOMES,
  BiomeDisplayNames,
  DEFAULT_NODE_THEMES,
  DEFAULT_ENTITY_TYPES,
  BIOME_ACT_PRESENCE,
  BIOME_DISTRIBUTIONS,
  ENEMY_TYPE_HOOKS,
  ENVIRONMENTAL_CONTEXTS,
  CONSEQUENCE_HOOKS,
  DREAM_HOOKS,
  TRAVEL_EVENT_HOOKS,
  ENVIRONMENTAL_STORYTELLING,
  CONDITION_HOOKS,
  TRADER_ARCHETYPES,
  PRICING_HOOKS,
} from '@node-gen-web/shared';
import { Biome } from '@node-gen-web/shared/types';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load seed data from JSON files
const beatRolesData = JSON.parse(readFileSync(join(__dirname, 'seed-data/beat-roles.json'), 'utf-8'));
const beatSequencesData = JSON.parse(readFileSync(join(__dirname, 'seed-data/beat-sequences.json'), 'utf-8'));
const styleGuideData = JSON.parse(readFileSync(join(__dirname, 'seed-data/style-guide.json'), 'utf-8'));
const vernacularData = JSON.parse(readFileSync(join(__dirname, 'seed-data/vernacular.json'), 'utf-8'));
const actTonesData = JSON.parse(readFileSync(join(__dirname, 'seed-data/act-tones.json'), 'utf-8'));

async function main() {
  console.log('Seeding database...');

  // Clear existing data (in reverse dependency order)
  console.log('Clearing existing data...');
  await db.delete(generationSettingsTable);
  await db.delete(actTonesTable);
  await db.delete(vernacularTable);
  await db.delete(styleGuideTable);
  await db.delete(beatSequencesTable);
  await db.delete(beatRolesTable);
  await db.delete(pricingHooksTable);
  await db.delete(traderArchetypesTable);
  await db.delete(conditionHooksTable);
  await db.delete(environmentalStorytellingTable);
  await db.delete(travelEventHooks);
  await db.delete(dreamHooksTable);
  await db.delete(consequenceHooksTable);
  await db.delete(environmentalContexts);
  await db.delete(enemyTypes);
  await db.delete(distributionsTable);
  await db.delete(biomesTable);
  console.log('✓ Existing data cleared');

  // 1. Seed biomes
  console.log('Seeding biomes...');
  for (const biome of ALL_BIOMES) {
    await db.insert(biomesTable).values({
      key: biome as any,
      displayName: BiomeDisplayNames[biome],
      themes: DEFAULT_NODE_THEMES[biome],
      entityTypes: DEFAULT_ENTITY_TYPES[biome],
      actPresence: BIOME_ACT_PRESENCE[biome],
    });
  }
  console.log('✓ Biomes seeded');

  // 2. Seed distributions
  console.log('Seeding distributions...');
  for (const biome of ALL_BIOMES) {
    const dist = BIOME_DISTRIBUTIONS[biome];
    for (const [nodeType, count] of Object.entries(dist)) {
      await db.insert(distributionsTable).values({
        biome: biome as any,
        nodeType: nodeType as any,
        count,
      });
    }
  }
  console.log('✓ Distributions seeded');

  // 3. Seed enemy types
  console.log('Seeding enemy types...');
  for (const biome of ALL_BIOMES) {
    const hooks = ENEMY_TYPE_HOOKS[biome];
    for (const hook of hooks) {
      await db.insert(enemyTypes).values({
        biome: biome as any,
        hook,
      });
    }
  }
  console.log('✓ Enemy types seeded');

  // 4. Seed environmental contexts
  console.log('Seeding environmental contexts...');
  for (const biome of ALL_BIOMES) {
    const contexts = ENVIRONMENTAL_CONTEXTS[biome];
    for (const context of contexts) {
      await db.insert(environmentalContexts).values({
        biome: biome as any,
        context,
      });
    }
  }
  console.log('✓ Environmental contexts seeded');

  // 5. Seed consequence hooks
  console.log('Seeding consequence hooks...');
  for (const biome of ALL_BIOMES) {
    const hooks = CONSEQUENCE_HOOKS[biome];
    for (const hook of hooks) {
      await db.insert(consequenceHooksTable).values({
        biome: biome as any,
        hook,
      });
    }
  }
  console.log('✓ Consequence hooks seeded');

  // 6. Seed dream hooks
  console.log('Seeding dream hooks...');
  for (const biome of ALL_BIOMES) {
    const hooks = DREAM_HOOKS[biome];
    for (const hook of hooks) {
      await db.insert(dreamHooksTable).values({
        biome: biome as any,
        hook,
      });
    }
  }
  console.log('✓ Dream hooks seeded');

  // 7. Seed travel event hooks
  console.log('Seeding travel event hooks...');
  for (const biome of ALL_BIOMES) {
    const hooks = TRAVEL_EVENT_HOOKS[biome];
    for (const hook of hooks) {
      await db.insert(travelEventHooks).values({
        biome: biome as any,
        hook,
      });
    }
  }
  console.log('✓ Travel event hooks seeded');

  // 8. Seed environmental storytelling
  console.log('Seeding environmental storytelling...');
  for (const biome of ALL_BIOMES) {
    const storytellings = ENVIRONMENTAL_STORYTELLING[biome];
    for (const storytelling of storytellings) {
      await db.insert(environmentalStorytellingTable).values({
        biome: biome as any,
        storytelling,
      });
    }
  }
  console.log('✓ Environmental storytelling seeded');

  // 9. Seed condition hooks
  console.log('Seeding condition hooks...');
  for (const biome of ALL_BIOMES) {
    const hooks = CONDITION_HOOKS[biome];
    for (const hook of hooks) {
      await db.insert(conditionHooksTable).values({
        biome: biome as any,
        hook,
      });
    }
  }
  console.log('✓ Condition hooks seeded');

  // 10. Seed trader archetypes
  console.log('Seeding trader archetypes...');
  for (const biome of ALL_BIOMES) {
    const archetypes = TRADER_ARCHETYPES[biome];
    for (const archetype of archetypes) {
      await db.insert(traderArchetypesTable).values({
        biome: biome as any,
        archetype,
      });
    }
  }
  console.log('✓ Trader archetypes seeded');

  // 11. Seed pricing hooks
  console.log('Seeding pricing hooks...');
  for (const [archetypeKey, hooks] of Object.entries(PRICING_HOOKS)) {
    for (const hook of hooks) {
      await db.insert(pricingHooksTable).values({
        archetypeKey,
        hook,
      });
    }
  }
  console.log('✓ Pricing hooks seeded');

  // 12. Seed beat roles
  console.log('Seeding beat roles...');
  for (const role of beatRolesData) {
    await db.insert(beatRolesTable).values(role);
  }
  console.log('✓ Beat roles seeded');

  // 13. Seed beat sequences
  console.log('Seeding beat sequences...');
  for (const sequence of beatSequencesData) {
    await db.insert(beatSequencesTable).values(sequence);
  }
  console.log('✓ Beat sequences seeded');

  // 14. Seed style guide
  console.log('Seeding style guide...');
  for (const guide of styleGuideData) {
    await db.insert(styleGuideTable).values(guide);
  }
  console.log('✓ Style guide seeded');

  // 15. Seed vernacular
  console.log('Seeding vernacular...');
  for (const term of vernacularData) {
    await db.insert(vernacularTable).values(term);
  }
  console.log('✓ Vernacular seeded');

  // 16. Seed act tones
  console.log('Seeding act tones...');
  for (const tone of actTonesData) {
    await db.insert(actTonesTable).values(tone);
  }
  console.log('✓ Act tones seeded');

  // 17. Seed default generation settings
  console.log('Seeding generation settings...');
  await db.insert(generationSettingsTable).values({
    batchSize: 5,
    criticThreshold: 70,
    enableCriticStage: true,
    defaultTemperature: 70,
    maxRetries: 3,
  });
  console.log('✓ Generation settings seeded');

  console.log('');
  console.log('🎉 Database seeding complete!');
  process.exit(0);
}

main().catch((err) => {
  console.error('Seeding failed!');
  console.error(err);
  process.exit(1);
});
