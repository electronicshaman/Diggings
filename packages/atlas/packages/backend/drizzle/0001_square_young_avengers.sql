CREATE TYPE "public"."beat_role" AS ENUM('setup', 'escalation', 'reveal', 'choice', 'consequence', 'button', 'tension', 'relief', 'foreshadow', 'reflection');--> statement-breakpoint
CREATE TYPE "public"."llm_provider_type" AS ENUM('openai', 'openrouter', 'anthropic');--> statement-breakpoint
CREATE TABLE "act_tones" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "act_tones_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"act" integer NOT NULL,
	"tone_name" varchar(100) NOT NULL,
	"description" text,
	"sensory_palette" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "beat_roles" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "beat_roles_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"key" varchar(50) NOT NULL,
	"display_name" varchar(100) NOT NULL,
	"description" text,
	"is_core" boolean DEFAULT false,
	"sort_order" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "beat_roles_key_unique" UNIQUE("key")
);
--> statement-breakpoint
CREATE TABLE "beat_sequences" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "beat_sequences_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"node_type" "node_type" NOT NULL,
	"sequence_key" varchar(100) NOT NULL,
	"beat_structure" jsonb NOT NULL,
	"weight" integer DEFAULT 1,
	"act_constraints" jsonb,
	"required_tags" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "generation_settings" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "generation_settings_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"batch_size" integer DEFAULT 5,
	"critic_threshold" integer DEFAULT 70,
	"enable_critic_stage" boolean DEFAULT true,
	"default_temperature" integer DEFAULT 70,
	"max_retries" integer DEFAULT 3,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "llm_providers" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "llm_providers_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"name" varchar(100) NOT NULL,
	"type" "llm_provider_type" NOT NULL,
	"base_url" varchar(255),
	"encrypted_api_key" text,
	"model" varchar(100) NOT NULL,
	"temperature" integer DEFAULT 70,
	"max_retries" integer DEFAULT 3,
	"is_active" boolean DEFAULT false,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "style_guide" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "style_guide_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"biome" "biome" NOT NULL,
	"atmosphere" text,
	"sensory_details" jsonb,
	"dangers" jsonb,
	"voice_notes" text,
	"antipatterns" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "style_guide_biome_unique" UNIQUE("biome")
);
--> statement-breakpoint
CREATE TABLE "vernacular" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "vernacular_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"term" varchar(100) NOT NULL,
	"definition" text NOT NULL,
	"era" varchar(50),
	"usage_notes" text,
	"sort_order" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "biomes" ADD COLUMN "atmosphere" text;--> statement-breakpoint
ALTER TABLE "biomes" ADD COLUMN "voice_notes" text;--> statement-breakpoint
ALTER TABLE "biomes" ADD COLUMN "updated_at" timestamp DEFAULT now();--> statement-breakpoint
ALTER TABLE "nodes" ADD COLUMN "critic_score" integer;--> statement-breakpoint
ALTER TABLE "nodes" ADD COLUMN "generated_by" varchar(50);