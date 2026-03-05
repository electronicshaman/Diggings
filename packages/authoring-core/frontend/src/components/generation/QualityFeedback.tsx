import { CheckCircle, XCircle, AlertCircle, Info, Lightbulb } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import type { CriticResult, CriticIssue } from '@node-gen-web/shared';

interface QualityFeedbackProps {
  critic: CriticResult;
  threshold?: number;
  compact?: boolean;
}

/**
 * Get severity color classes for backgrounds and text
 */
function getSeverityColor(severity: CriticIssue['severity']): {
  bg: string;
  border: string;
  text: string;
  icon: string;
} {
  switch (severity) {
    case 'critical':
      return {
        bg: 'bg-red-50 dark:bg-red-950/30',
        border: 'border-red-200 dark:border-red-800',
        text: 'text-red-900 dark:text-red-100',
        icon: 'text-red-500',
      };
    case 'major':
      return {
        bg: 'bg-amber-50 dark:bg-amber-950/30',
        border: 'border-amber-200 dark:border-amber-800',
        text: 'text-amber-900 dark:text-amber-100',
        icon: 'text-amber-500',
      };
    case 'minor':
      return {
        bg: 'bg-blue-50 dark:bg-blue-950/30',
        border: 'border-blue-200 dark:border-blue-800',
        text: 'text-blue-900 dark:text-blue-100',
        icon: 'text-blue-500',
      };
  }
}

/**
 * Get icon for severity level
 */
function SeverityIcon({ severity }: { severity: CriticIssue['severity'] }) {
  const colors = getSeverityColor(severity);
  const iconClass = cn('size-5', colors.icon);

  switch (severity) {
    case 'critical':
      return <XCircle className={iconClass} />;
    case 'major':
      return <AlertCircle className={iconClass} />;
    case 'minor':
      return <Info className={iconClass} />;
  }
}

/**
 * Display detailed critic feedback with issues, suggestions, and strengths
 */
export function QualityFeedback({ critic, threshold = 70, compact = false }: QualityFeedbackProps) {
  const { pass, score, issues, strengths, repairInstructions } = critic;
  const groupedIssues = {
    critical: issues.filter((i) => i.severity === 'critical'),
    major: issues.filter((i) => i.severity === 'major'),
    minor: issues.filter((i) => i.severity === 'minor'),
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {pass ? (
              <CheckCircle className="size-5 text-green-500" />
            ) : (
              <XCircle className="size-5 text-destructive" />
            )}
            <span>Quality Assessment</span>
          </div>
          <div className="flex items-baseline gap-2">
            <span
              className={cn(
                'text-3xl font-bold tabular-nums',
                score >= threshold ? 'text-green-500' : 'text-amber-500'
              )}
            >
              {score}
            </span>
            <span className="text-sm text-muted-foreground">/100</span>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Pass/Fail Status */}
        <div
          className={cn(
            'rounded-lg border p-3 text-sm',
            pass
              ? 'border-green-200 bg-green-50 text-green-900 dark:border-green-800 dark:bg-green-950/30 dark:text-green-100'
              : 'border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-800 dark:bg-amber-950/30 dark:text-amber-100'
          )}
        >
          {pass ? (
            <span className="font-medium">✓ Passed quality check</span>
          ) : (
            <span className="font-medium">✗ Below threshold ({threshold})</span>
          )}
        </div>

        {/* Strengths Section */}
        {strengths.length > 0 && (
          <div className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-medium text-green-600 dark:text-green-400">
              <CheckCircle className="size-4" />
              <span>Strengths ({strengths.length})</span>
            </div>
            <ScrollArea className={cn(compact ? 'max-h-24' : 'max-h-48')}>
              <ul className="space-y-1 text-sm">
                {strengths.map((strength, idx) => (
                  <li key={idx} className="flex gap-2">
                    <span className="text-green-500">•</span>
                    <span>{strength}</span>
                  </li>
                ))}
              </ul>
            </ScrollArea>
          </div>
        )}

        {/* Issues Section */}
        {issues.length > 0 && (
          <div className="space-y-3">
            <Separator />
            <div className="text-sm font-medium">Issues ({issues.length})</div>
            <ScrollArea className={cn(compact ? 'max-h-48' : 'max-h-96')}>
              <div className="space-y-3">
                {/* Critical Issues */}
                {groupedIssues.critical.length > 0 && (
                  <div className="space-y-2">
                    {groupedIssues.critical.map((issue, idx) => (
                      <IssueCard key={`critical-${idx}`} issue={issue} />
                    ))}
                  </div>
                )}

                {/* Major Issues */}
                {groupedIssues.major.length > 0 && (
                  <div className="space-y-2">
                    {groupedIssues.major.map((issue, idx) => (
                      <IssueCard key={`major-${idx}`} issue={issue} />
                    ))}
                  </div>
                )}

                {/* Minor Issues */}
                {groupedIssues.minor.length > 0 && (
                  <div className="space-y-2">
                    {groupedIssues.minor.map((issue, idx) => (
                      <IssueCard key={`minor-${idx}`} issue={issue} />
                    ))}
                  </div>
                )}
              </div>
            </ScrollArea>
          </div>
        )}

        {/* Repair Instructions */}
        {repairInstructions && (
          <>
            <Separator />
            <div
              className="space-y-2 rounded-lg border border-blue-200 bg-blue-50 p-3 dark:border-blue-800 dark:bg-blue-950/30"
            >
              <div className="flex items-center gap-2 text-sm font-medium text-blue-900 dark:text-blue-100">
                <Info className="size-4 text-blue-500" />
                <span>Repair Instructions</span>
              </div>
              <p className="text-sm text-blue-900 dark:text-blue-100">{repairInstructions}</p>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

/**
 * Individual issue card
 */
function IssueCard({ issue }: { issue: CriticIssue }) {
  const colors = getSeverityColor(issue.severity);

  return (
    <div className={cn('rounded-lg border p-3 space-y-2', colors.bg, colors.border)}>
      {/* Issue Header */}
      <div className="flex items-start gap-2">
        <SeverityIcon severity={issue.severity} />
        <div className="flex-1 space-y-1">
          <div className="flex items-center gap-2 flex-wrap">
            <Badge variant="outline" className="text-xs capitalize">
              {issue.severity}
            </Badge>
            <Badge variant="secondary" className="text-xs">
              {issue.category}
            </Badge>
            {issue.beatId && (
              <span className="text-xs text-muted-foreground">Beat: {issue.beatId}</span>
            )}
          </div>
          <p className={cn('text-sm font-medium', colors.text)}>{issue.description}</p>
        </div>
      </div>

      {/* Suggestion */}
      {issue.suggestion && (
        <div className={cn('flex gap-2 text-sm italic', colors.text)}>
          <Lightbulb className="size-4 shrink-0 mt-0.5" />
          <span>{issue.suggestion}</span>
        </div>
      )}
    </div>
  );
}
