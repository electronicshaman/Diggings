CREATE TYPE "public"."job_status" AS ENUM('pending', 'running', 'completed', 'failed');--> statement-breakpoint
CREATE TABLE "generation_jobs" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "generation_jobs_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"job_id" varchar(50) NOT NULL,
	"status" "job_status" DEFAULT 'pending' NOT NULL,
	"node_type" "node_type" NOT NULL,
	"biome" "biome" NOT NULL,
	"request" jsonb NOT NULL,
	"progress" integer DEFAULT 0,
	"current_stage" varchar(50),
	"result" jsonb,
	"error" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"expires_at" timestamp NOT NULL,
	CONSTRAINT "generation_jobs_job_id_unique" UNIQUE("job_id")
);
--> statement-breakpoint
CREATE INDEX "job_id_idx" ON "generation_jobs" USING btree ("job_id");--> statement-breakpoint
CREATE INDEX "expires_at_idx" ON "generation_jobs" USING btree ("expires_at");