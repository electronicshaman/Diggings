CREATE TYPE "public"."accessibility_tier" AS ENUM('Starting', 'Class', 'Neutral', 'Rare');--> statement-breakpoint
CREATE TYPE "public"."card_handling" AS ENUM('Standard', 'Equipped', 'Flash', 'Keep', 'Hold', 'Oneshot');--> statement-breakpoint
CREATE TYPE "public"."card_owner" AS ENUM('PLAYER', 'ENEMY', 'NEUTRAL');--> statement-breakpoint
CREATE TYPE "public"."card_rarity" AS ENUM('Common', 'Uncommon', 'Rare', 'Eldritch');--> statement-breakpoint
CREATE TYPE "public"."card_type" AS ENUM('Attack', 'Skill', 'Power', 'Fortune', 'Hex', 'Curse');--> statement-breakpoint
CREATE TABLE "cards" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "cards_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"card_id" varchar(100) NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"card_type" "card_type" NOT NULL,
	"costs" jsonb NOT NULL,
	"effects" jsonb NOT NULL,
	"rarity" "card_rarity" NOT NULL,
	"card_owner" "card_owner" NOT NULL,
	"handling" "card_handling" NOT NULL,
	"class_affinity" jsonb NOT NULL,
	"accessibility_tier" "accessibility_tier" NOT NULL,
	"flavor_text" text,
	"base_durability" integer,
	"volatile_bonus" boolean,
	"luck_modifier" integer,
	"enemy_faction" varchar(100),
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "cards_card_id_unique" UNIQUE("card_id")
);
--> statement-breakpoint
CREATE INDEX "card_id_idx" ON "cards" USING btree ("card_id");