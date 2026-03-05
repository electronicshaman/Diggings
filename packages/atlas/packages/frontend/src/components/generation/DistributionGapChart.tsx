import { useMemo } from 'react';
import { useDistributions, useBiomes } from '@/hooks/useConfig';
import { useNodes } from '@/hooks/useNodes';
import { DistributionGapMatrix } from '@diggings/authoring-core-frontend';
import { NodeType, NodeTypeDisplayNames, BiomeDisplayNames, type Biome } from '@node-gen-web/shared';

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
    <DistributionGapMatrix
      title="Distribution Gaps"
      description="Target vs actual node counts by biome and type"
      biomeIds={biomeIds}
      nodeTypes={nodeTypes}
      labels={{ biome: BiomeDisplayNames, nodeType: NodeTypeDisplayNames }}
      matrix={matrix}
      onSelectGap={onSelectGap}
    />
  );
}
