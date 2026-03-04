CREATE TYPE "public"."biome" AS ENUM('township', 'the_diggings', 'the_bush', 'the_mines', 'the_waste', 'the_scar', 'sacred_site', 'the_river');--> statement-breakpoint
CREATE TYPE "public"."dilemma_type" AS ENUM('moral', 'practical', 'survival');--> statement-breakpoint
CREATE TYPE "public"."interruption_chance" AS ENUM('none', 'low', 'medium', 'high');--> statement-breakpoint
CREATE TYPE "public"."node_type" AS ENUM('combat', 'choice', 'state_check', 'trade', 'passage', 'rest', 'transition');--> statement-breakpoint
CREATE TYPE "public"."rest_type" AS ENUM('safe', 'risky', 'sacred');--> statement-breakpoint
CREATE TABLE "biomes" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "biomes_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"key" "biome" NOT NULL,
	"display_name" varchar(100) NOT NULL,
	"themes" jsonb NOT NULL,
	"entity_types" jsonb NOT NULL,
	"act_presence" jsonb NOT NULL,
	CONSTRAINT "biomes_key_unique" UNIQUE("key")
);
--> statement-breakpoint
CREATE TABLE "condition_hooks" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "condition_hooks_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"hook" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "consequence_hooks" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "consequence_hooks_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"hook" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "distributions" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "distributions_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"node_type" "node_type" NOT NULL,
	"count" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "dream_hooks" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "dream_hooks_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"hook" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "enemy_types" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "enemy_types_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"hook" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "environmental_contexts" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "environmental_contexts_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"context" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "environmental_storytelling" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "environmental_storytelling_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"storytelling" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "nodes" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "nodes_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"node_id" varchar(50) NOT NULL,
	"type" "node_type" NOT NULL,
	"biome" "biome" NOT NULL,
	"name" varchar(255) NOT NULL,
	"acts" jsonb NOT NULL,
	"act_variant" boolean DEFAULT false,
	"is_replaceable" boolean NOT NULL,
	"replacement_tags" jsonb NOT NULL,
	"themes" jsonb NOT NULL,
	"entity_types" jsonb NOT NULL,
	"estimated_combat_difficulty" integer,
	"eligibility" jsonb,
	"resource_cost" jsonb,
	"potential_rewards" jsonb,
	"content" jsonb,
	"act_variants" jsonb,
	"enemy_type_hooks" jsonb,
	"environmental_context" varchar(255),
	"consequence_hooks" jsonb,
	"dilemma_type" "dilemma_type",
	"trader_archetype" varchar(100),
	"pricing_hooks" jsonb,
	"rest_type" "rest_type",
	"interruption_chance" "interruption_chance",
	"dream_hooks" jsonb,
	"travel_event_hooks" jsonb,
	"environmental_storytelling" text,
	"condition_hooks" jsonb,
	"branch_targets" jsonb,
	"act_change_trigger" integer,
	"narrative_summary" text,
	"world_state_shifts" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "nodes_node_id_unique" UNIQUE("node_id")
);
--> statement-breakpoint
CREATE TABLE "pricing_hooks" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "pricing_hooks_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"archetype_key" varchar(100) NOT NULL,
	"hook" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "trader_archetypes" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "trader_archetypes_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"archetype" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "travel_event_hooks" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "travel_event_hooks_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"hook" varchar(100) NOT NULL
);
--> statement-breakpoint
CREATE INDEX "type_idx" ON "nodes" USING btree ("type");--> statement-breakpoint
CREATE INDEX "biome_idx" ON "nodes" USING btree ("biome");--> statement-breakpoint
CREATE INDEX "node_id_idx" ON "nodes" USING btree ("node_id");