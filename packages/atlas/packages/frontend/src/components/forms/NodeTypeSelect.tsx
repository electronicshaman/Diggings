import {
  Swords,
  GitFork,
  Store,
  Moon,
  Footprints,
  CheckCircle,
  ArrowRightCircle,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { NodeType, NodeTypeDisplayNames } from '@atlas/shared';
import { useFormStore } from '@/store/form-store';
import type { LucideIcon } from 'lucide-react';

const nodeTypeConfig: Record<
  NodeType,
  { icon: LucideIcon; description: string }
> = {
  [NodeType.Combat]: {
    icon: Swords,
    description: 'Battle encounters with enemies and environmental hazards',
  },
  [NodeType.Choice]: {
    icon: GitFork,
    description: 'Branching decisions with meaningful consequences',
  },
  [NodeType.Trade]: {
    icon: Store,
    description: 'Merchant interactions and resource exchanges',
  },
  [NodeType.Rest]: {
    icon: Moon,
    description: 'Recovery points with potential for dreams or interruptions',
  },
  [NodeType.Passage]: {
    icon: Footprints,
    description: 'Travel events and environmental storytelling moments',
  },
  [NodeType.StateCheck]: {
    icon: CheckCircle,
    description: 'Conditional branching based on player state',
  },
  [NodeType.Transition]: {
    icon: ArrowRightCircle,
    description: 'Act transitions and major narrative shifts',
  },
};

export function NodeTypeSelect() {
  const { setFormData, nextStep } = useFormStore();

  const handleSelect = (type: NodeType) => {
    setFormData({ type });
    nextStep();
  };

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-semibold">Select Node Type</h2>
        <p className="text-sm text-muted-foreground">
          Choose the type of node you want to create
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {Object.values(NodeType).map((type) => {
          const config = nodeTypeConfig[type];
          const Icon = config.icon;

          return (
            <Card
              key={type}
              className="cursor-pointer transition-colors hover:bg-accent"
              onClick={() => handleSelect(type)}
            >
              <CardContent className="flex flex-col items-center gap-3 p-6 text-center">
                <Icon className="size-8 text-primary" />
                <div>
                  <h3 className="font-medium">{NodeTypeDisplayNames[type]}</h3>
                  <p className="text-sm text-muted-foreground">
                    {config.description}
                  </p>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
