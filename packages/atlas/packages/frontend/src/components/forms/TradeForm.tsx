import { useFormContext, Controller } from 'react-hook-form';
import { useLookup } from '@/hooks/useConfig';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type { TradeNodeMetadata } from '@node-gen-web/shared';

export function TradeForm() {
  const { control, watch } = useFormContext<TradeNodeMetadata>();
  const biome = watch('biome');
  const traderArchetype = watch('traderArchetype');

  const { data: traderArchetypes, isLoading: loadingArchetypes } = useLookup('trader-archetypes', biome);
  const { data: pricingHooks, isLoading: loadingPricing } = useLookup(
    traderArchetype ? `pricing-hooks` : '',
    biome
  );

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Trader Archetype</Label>
        {loadingArchetypes ? (
          <Skeleton className="h-10 w-full" />
        ) : (
          <Controller
            name="traderArchetype"
            control={control}
            render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Select archetype" />
                </SelectTrigger>
                <SelectContent>
                  {traderArchetypes?.map((item) => (
                    <SelectItem key={item.hook} value={item.hook}>
                      {item.hook}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )}
          />
        )}
      </div>

      <div className="space-y-2">
        <Label>Pricing Hooks</Label>
        {loadingPricing ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <Controller
            name="pricingHooks"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2">
                {pricingHooks?.map((item) => (
                  <label key={item.hook} className="flex items-center gap-2 cursor-pointer">
                    <Checkbox
                      checked={field.value?.includes(item.hook)}
                      onCheckedChange={(checked) => {
                        const current = field.value || [];
                        if (checked) {
                          field.onChange([...current, item.hook]);
                        } else {
                          field.onChange(current.filter((v) => v !== item.hook));
                        }
                      }}
                    />
                    <span className="text-sm">{item.hook}</span>
                  </label>
                ))}
              </div>
            )}
          />
        )}
      </div>
    </div>
  );
}
