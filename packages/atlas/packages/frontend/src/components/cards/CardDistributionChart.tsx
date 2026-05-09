import { CARD_TYPES, CARD_RARITIES, CARD_DISTRIBUTION } from '@atlas/shared';
import type { Card } from '@atlas/shared';
import { useCards } from '@/hooks/useCards';

interface CardDistributionChartProps {
  targetTotal: number;
  cardOwner?: string;
}

export function CardDistributionChart({ targetTotal, cardOwner }: CardDistributionChartProps) {
  const { data, isLoading } = useCards({ limit: 1000, ...(cardOwner ? { cardOwner } : {}) });

  // Compute total distribution weight
  let totalWeight = 0;
  for (const type of CARD_TYPES) {
    for (const rarity of CARD_RARITIES) {
      totalWeight += CARD_DISTRIBUTION[type][rarity];
    }
  }

  // Count actual cards per type+rarity
  const actual: Partial<Record<string, Partial<Record<string, number>>>> = {};
  if (data?.cards) {
    for (const card of data.cards as Card[]) {
      if (!actual[card.cardType]) actual[card.cardType] = {};
      actual[card.cardType]![card.rarity] = (actual[card.cardType]![card.rarity] ?? 0) + 1;
    }
  }

  if (isLoading) {
    return <div className="text-sm text-muted-foreground">Loading distribution...</div>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm border-collapse">
        <thead>
          <tr>
            <th className="text-left py-1 pr-4 font-medium text-muted-foreground">Type</th>
            {CARD_RARITIES.map((rarity) => (
              <th key={rarity} className="text-center py-1 px-2 font-medium text-muted-foreground w-28">
                {rarity}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {CARD_TYPES.map((type) => (
            <tr key={type} className="border-t border-border">
              <td className="py-1.5 pr-4 font-medium">{type}</td>
              {CARD_RARITIES.map((rarity) => {
                const weight = CARD_DISTRIBUTION[type][rarity];
                const target = Math.round((targetTotal * weight) / totalWeight);
                const have = actual[type]?.[rarity] ?? 0;
                const gap = Math.max(0, target - have);
                const ratio = target === 0 ? 1 : have / target;

                let colorClass = 'text-green-600 dark:text-green-400';
                if (ratio < 0.5) colorClass = 'text-red-500';
                else if (ratio < 1) colorClass = 'text-yellow-500';

                return (
                  <td key={rarity} className="text-center py-1.5 px-2">
                    <span className={colorClass}>
                      {have}/{target}
                    </span>
                    {gap > 0 && (
                      <span className="ml-1 text-xs text-muted-foreground">(+{gap})</span>
                    )}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
      <p className="mt-2 text-xs text-muted-foreground">
        Showing actual / target. Green = at target, yellow = partial, red = needs filling.
      </p>
    </div>
  );
}
