import { useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import { useDistributions, useBiomes } from '@/hooks/useConfig';
import { useNodes } from '@/hooks/useNodes';
import { NodeType, NodeTypeDisplayNames, BiomeDisplayNames, type Biome } from '@node-gen-web/shared';

interface GapCellProps {
  target: number;
  actual: number;
  biome: Biome;
  nodeType: NodeType;
  onClick?: (biome: Biome, nodeType: NodeType, gap: number) => void;
}

function GapCell({ target, actual, biome, nodeType, onClick }: GapCellProps) {
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
              <strong>{NodeTypeDisplayNames[nodeType]}</strong> in{' '}
              <strong>{BiomeDisplayNames[biome]}</strong>
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

interface DistributionGapChartProps {
  onSelectGap?: (biome: Biome, nodeType: NodeType, gap: number) => void;
}

export function DistributionGapChart({ onSelectGap }: DistributionGapChartProps) {
  const { data: distributions } = useDistributions();
  const { data: biomes } = useBiomes();
  const { data: nodesData } = useNodes({ limit: 1000 });

  const nodeTypes = Object.values(NodeType);

  const matrix = useMemo(() => {
    if (!distributions || !biomes || !nodesData) return null;

    const biomeIds = biomes.map((b) => b.id);
    const result: Record<Biome, Record<NodeType, { target: number; actual: number }>> = {} as any;

    for (const biome of biomeIds) {
      result[biome] = {} as Record<NodeType, { target: number; actual: number }>;
      for (const nodeType of nodeTypes) {
        const dist = distributions.find((d) => d.biome === biome);
        const target = dist?.weights[nodeType] || 0;
        const actual = nodesData.nodes.filter(
          (n) => n.biome === biome && n.type === nodeType
        ).length;
        result[biome][nodeType] = { target, actual };
      }
    }

    return result;
  }, [distributions, biomes, nodesData, nodeTypes]);

  const totalGap = useMemo(() => {
    if (!matrix) return 0;
    let total = 0;
    for (const biome of Object.keys(matrix) as Biome[]) {
      for (const nodeType of nodeTypes) {
        const { target, actual } = matrix[biome][nodeType];
        if (target > actual) total += target - actual;
      }
    }
    return total;
  }, [matrix, nodeTypes]);

  if (!matrix || !biomes) {
    return (
      <Card>
        <CardContent className="flex h-64 items-center justify-center">
          <p className="text-muted-foreground">Loading distribution data...</p>
        </CardContent>
      </Card>
    );
  }

  const biomeIds = biomes.map((b) => b.id);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Distribution Gaps</CardTitle>
            <CardDescription>
              Target vs actual node counts by biome and type
            </CardDescription>
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
                    {NodeTypeDisplayNames[type]}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {biomeIds.map((biome) => (
                <tr key={biome}>
                  <td className="whitespace-nowrap p-2 text-sm font-medium">
                    {BiomeDisplayNames[biome]}
                  </td>
                  {nodeTypes.map((type) => (
                    <td key={`${biome}-${type}`} className="p-1">
                      <GapCell
                        target={matrix[biome][type].target}
                        actual={matrix[biome][type].actual}
                        biome={biome}
                        nodeType={type}
                        onClick={onSelectGap}
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
