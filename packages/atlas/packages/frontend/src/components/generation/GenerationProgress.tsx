import { CheckCircle, Circle, Loader2, XCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Progress } from '@/components/ui/progress';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import type { GenerationState } from '@/hooks/useGeneration';
import { QualityFeedback } from './QualityFeedback';

interface GenerationProgressProps {
  state: GenerationState;
  onCancel?: () => void;
  onRetry?: () => void;
  onAccept?: () => void;
  showContent?: boolean;
  threshold?: number;
}

const STAGES = [
  { key: 'outlining', label: 'Creating Beat Outline', progress: 33 },
  { key: 'expanding', label: 'Expanding to Prose', progress: 66 },
  { key: 'reviewing', label: 'Reviewing Quality', progress: 100 },
] as const;

function StageIcon({ stage, currentStage }: { stage: string; currentStage: string }) {
  const stageIndex = STAGES.findIndex((s) => s.key === stage);
  const currentIndex = STAGES.findIndex((s) => s.key === currentStage);

  if (currentStage === 'error') {
    return stageIndex <= currentIndex ? (
      <XCircle className="size-5 text-destructive" />
    ) : (
      <Circle className="size-5 text-muted-foreground" />
    );
  }

  if (currentStage === 'completed' || stageIndex < currentIndex) {
    return <CheckCircle className="size-5 text-green-500" />;
  }

  if (stageIndex === currentIndex) {
    return <Loader2 className="size-5 animate-spin text-primary" />;
  }

  return <Circle className="size-5 text-muted-foreground" />;
}

export function GenerationProgress({
  state,
  onCancel,
  onRetry,
  onAccept,
  showContent = false,
  threshold = 70,
}: GenerationProgressProps) {
  const { stage, progress, message, criticScore, criticResult, content, error } = state;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          {stage === 'completed' && <CheckCircle className="size-5 text-green-500" />}
          {stage === 'error' && <XCircle className="size-5 text-destructive" />}
          {stage !== 'completed' && stage !== 'error' && stage !== 'idle' && (
            <Loader2 className="size-5 animate-spin" />
          )}
          <span>
            {stage === 'idle' && 'Ready to Generate'}
            {stage === 'completed' && 'Generation Complete'}
            {stage === 'error' && 'Generation Failed'}
            {stage !== 'idle' && stage !== 'completed' && stage !== 'error' && 'Generating...'}
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Stage progress */}
        <div className="space-y-4">
          {STAGES.map((s) => (
            <div key={s.key} className="flex items-center gap-3">
              <StageIcon stage={s.key} currentStage={stage} />
              <span
                className={cn(
                  'text-sm',
                  stage === s.key && 'font-medium',
                  stage !== s.key &&
                    STAGES.findIndex((x) => x.key === stage) < STAGES.findIndex((x) => x.key === s.key) &&
                    'text-muted-foreground'
                )}
              >
                {s.label}
              </span>
            </div>
          ))}
        </div>

        {/* Overall progress bar */}
        {stage !== 'idle' && (
          <div className="space-y-2">
            <Progress value={progress} className="h-2" />
            <p className="text-sm text-muted-foreground">{message}</p>
          </div>
        )}

        {/* Critic score / Quality feedback */}
        {criticResult ? (
          <QualityFeedback critic={criticResult} threshold={threshold} compact />
        ) : typeof criticScore === 'number' ? (
          // Fallback for backward compatibility
          <div className="rounded-lg border bg-muted/50 p-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Quality Score</span>
              <span
                className={cn(
                  'text-2xl font-bold',
                  criticScore >= 70 ? 'text-green-500' : 'text-amber-500'
                )}
              >
                {criticScore}
              </span>
            </div>
            <p className="mt-1 text-xs text-muted-foreground">
              {criticScore >= 70 ? 'Passed quality check' : 'Below threshold (70)'}
            </p>
          </div>
        ) : null}

        {/* Error message */}
        {error && (
          <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-4">
            <p className="text-sm text-destructive">{error}</p>
          </div>
        )}

        {/* Content preview */}
        {showContent && content != null ? (
          <div className="max-h-64 overflow-auto rounded-lg border bg-muted/50 p-4">
            <pre className="whitespace-pre-wrap text-xs">
              {JSON.stringify(content, null, 2)}
            </pre>
          </div>
        ) : null}

        {/* Action buttons */}
        <div className="flex gap-2">
          {stage !== 'idle' && stage !== 'completed' && stage !== 'error' && onCancel && (
            <Button variant="outline" onClick={onCancel}>
              Cancel
            </Button>
          )}
          {stage === 'error' && onRetry && (
            <Button variant="outline" onClick={onRetry}>
              Retry
            </Button>
          )}
          {stage === 'completed' && onAccept && (
            <Button onClick={onAccept}>Accept & Save</Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
