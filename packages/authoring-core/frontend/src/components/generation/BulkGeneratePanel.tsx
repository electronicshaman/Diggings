import React from 'react';

export type BulkStatus = 'idle' | 'running' | 'paused' | 'completed' | 'error';

export interface BulkProgress {
  status: BulkStatus;
  total: number;
  completed: number;
  failed: number;
  currentNode?: string;
  errors?: string[];
}

export interface BulkGeneratePanelProps {
  title?: string;
  description?: string;
  progress: BulkProgress;
  onPause?: () => void;
  onCancel?: () => void;
  onReset?: () => void;
  children?: React.ReactNode;
}

export function BulkGeneratePanel({
  title = 'Bulk Generate',
  description = 'Generate multiple items at once',
  progress,
  onPause,
  onCancel,
  onReset,
  children,
}: BulkGeneratePanelProps) {
  const isRunning = progress.status === 'running' || progress.status === 'paused';

  return (
    <div className="rounded-lg border bg-card text-card-foreground">
      <div className="border-b px-6 py-4">
        <h3 className="text-lg font-semibold">{title}</h3>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>

      <div className="p-6">
        {isRunning ? (
          <div className="space-y-4">
            <div className="text-sm">
              {progress.status === 'paused' ? 'Paused' : 'Generating'}...
            </div>
            <div className="h-2 w-full rounded bg-muted">
              <div
                className="h-2 rounded bg-primary"
                style={{ width: `${((progress.completed + progress.failed) / Math.max(1, progress.total)) * 100}%` }}
              />
            </div>
            {progress.currentNode && (
              <p className="text-sm text-muted-foreground">
                Currently generating: {progress.currentNode}
              </p>
            )}
            <div className="flex gap-3">
              {progress.completed > 0 && (
                <span className="rounded border px-2 py-1 text-xs">✓ {progress.completed} completed</span>
              )}
              {progress.failed > 0 && (
                <span className="rounded border border-destructive/50 px-2 py-1 text-xs text-destructive">
                  ✗ {progress.failed} failed
                </span>
              )}
            </div>
            <div className="flex gap-2">
              {onPause && (
                <button
                  className="rounded border px-3 py-2 text-sm"
                  onClick={onPause}
                >
                  {progress.status === 'paused' ? 'Resume' : 'Pause'}
                </button>
              )}
              {onCancel && (
                <button
                  className="rounded border border-destructive/50 px-3 py-2 text-sm text-destructive"
                  onClick={onCancel}
                >
                  Cancel
                </button>
              )}
            </div>
          </div>
        ) : progress.status === 'completed' ? (
          <div className="space-y-3">
            <div className="rounded border border-green-500/50 bg-green-500/10 p-4">
              <p className="font-medium text-green-500">Generation Complete!</p>
              <p className="text-sm text-muted-foreground">
                Successfully generated {progress.completed} items
                {progress.failed > 0 && ` (${progress.failed} failed)`}
              </p>
            </div>
            {progress.errors?.length ? (
              <div className="max-h-32 overflow-y-auto rounded border p-2 text-xs text-muted-foreground">
                {progress.errors.map((err, i) => (
                  <p key={i}>{err}</p>
                ))}
              </div>
            ) : null}
            {onReset && (
              <button className="rounded border px-3 py-2 text-sm" onClick={onReset}>
                Generate More
              </button>
            )}
          </div>
        ) : progress.status === 'error' ? (
          <div className="space-y-3">
            <div className="rounded border border-red-500/50 bg-red-500/10 p-4">
              <p className="font-medium text-red-500">Generation Failed</p>
              {progress.errors?.map((err, i) => (
                <p key={i} className="text-sm text-muted-foreground">
                  {err}
                </p>
              ))}
            </div>
            {onReset && (
              <button className="rounded border px-3 py-2 text-sm" onClick={onReset}>
                Try Again
              </button>
            )}
          </div>
        ) : (
          <>{children}</>
        )}
      </div>
    </div>
  );
}
