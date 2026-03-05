import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';

export interface GapCellConfig<TBiome extends string, TNodeType extends string> {
  biome: TBiome;
  nodeType: TNodeType;
  target: number;
  actual: number;
}

export interface DistributionGapMatrixProps<TBiome extends string, TNodeType extends string> {
  title?: string;
  description?: string;
  biomeIds: TBiome[];
  nodeTypes: TNodeType[];
  labels: {
    biome: Record<TBiome, string>;
    nodeType: Record<TNodeType, string>;
  };
  matrix: Record<TBiome, Record<TNodeType, { target: number; actual: number }>>;
  onSelectGap?: (biome: TBiome, nodeType: TNodeType, gap: number) => void;
}

function GapCell<TBiome extends string, TNodeType extends string>({
  target,
  actual,
  biome,
  nodeType,
  onClick,
  labels,
}: {
  target: number;
  actual: number;
  biome: TBiome;
  nodeType: TNodeType;
  onClick?: (biome: TBiome, nodeType: TNodeType, gap: number) => void;
  labels: { biome: Record<TBiome, string>; nodeType: Record<TNodeType, string> };
}) {
  const gap = target - actual;

  const getColor = () => {
    if (gap > 0) return 'bg-red-500/20 border-red-500/50 hover:bg-red-500/30';
    if (gap < 0) return 'bg-amber-500/20 border-amber-500/50 hover:bg-amber-500/30';
    return 'bg-green-500/20 border-green-500/50';
  };

  const getTextColor = () => {
    if (gap > 0) return 'text-red-500';
    if (gap < 0) return 'text-amber-500';
    return 'text-green-500';
  };

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <button
            className={cn(
              'flex size-full min-h-12 flex-col items-center justify-center rounded border p-2 text-center transition-colors',
              getColor(),
              gap > 0 && onClick && 'cursor-pointer'
            )}
            onClick={() => gap > 0 && onClick?.(biome, nodeType, gap)}
            disabled={gap <= 0}
          >
            <span className={cn('text-lg font-bold', getTextColor())}>{actual}</span>
            <span className="text-xs text-muted-foreground">/ {target}</span>
          </button>
        </TooltipTrigger>
        <TooltipContent>
          <div className="space-y-1 text-sm">
            <p>
              <strong>{labels.nodeType[nodeType]}</strong> in{' '}
              <strong>{labels.biome[biome]}</strong>
            </p>
            <p>
              Target: {target} | Actual: {actual}
            </p>
            {gap > 0 && (
              <p className="text-red-400">
                Missing: {gap} node{gap !== 1 ? 's' : ''}
              </p>
            )}
            {gap < 0 && (
              <p className="text-amber-400">
                Excess: {Math.abs(gap)} node{Math.abs(gap) !== 1 ? 's' : ''}
              </p>
            )}
            {gap === 0 && <p className="text-green-400">Target met!</p>}
          </div>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}

export function DistributionGapMatrix<TBiome extends string, TNodeType extends string>({
  title = 'Distribution Gaps',
  description = 'Target vs actual counts by group',
  biomeIds,
  nodeTypes,
  labels,
  matrix,
  onSelectGap,
}: DistributionGapMatrixProps<TBiome, TNodeType>) {
  const totalGap = biomeIds.reduce((total, biome) => {
    return (
      total +
      nodeTypes.reduce((inner, nodeType) => {
        const { target, actual } = matrix[biome][nodeType];
        return inner + (target > actual ? target - actual : 0);
      }, 0)
    );
  }, 0);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>{title}</CardTitle>
            <CardDescription>{description}</CardDescription>
          </div>
          {totalGap > 0 && (
            <Badge variant="destructive" className="text-lg">
              {totalGap} missing
            </Badge>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead>
              <tr>
                <th className="p-2 text-left text-sm font-medium text-muted-foreground">Biome</th>
                {nodeTypes.map((type) => (
                  <th
                    key={type}
                    className="p-2 text-center text-xs font-medium text-muted-foreground"
                  >
                    {labels.nodeType[type]}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {biomeIds.map((biome) => (
                <tr key={biome}>
                  <td className="whitespace-nowrap p-2 text-sm font-medium">
                    {labels.biome[biome]}
                  </td>
                  {nodeTypes.map((type) => (
                    <td key={`${biome}-${type}`} className="p-1">
                      <GapCell
                        target={matrix[biome][type].target}
                        actual={matrix[biome][type].actual}
                        biome={biome}
                        nodeType={type}
                        onClick={onSelectGap}
                        labels={labels}
                      />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex items-center justify-center gap-6 text-sm">
          <div className="flex items-center gap-2">
            <div className="size-4 rounded border border-red-500/50 bg-red-500/20" />
            <span>Missing</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="size-4 rounded border border-amber-500/50 bg-amber-500/20" />
            <span>Excess</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="size-4 rounded border border-green-500/50 bg-green-500/20" />
            <span>Complete</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
