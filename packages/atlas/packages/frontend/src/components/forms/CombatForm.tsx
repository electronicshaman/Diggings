import { useFormContext, Controller } from 'react-hook-form';
import { useLookup } from '@/hooks/useConfig';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Skeleton } from '@/components/ui/skeleton';
import { Slider } from '@/components/ui/slider';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type { CombatNodeMetadata } from '@node-gen-web/shared';

export function CombatForm() {
  const { control, watch } = useFormContext<CombatNodeMetadata>();
  const biome = watch('biome');

  const { data: enemyTypes, isLoading: loadingEnemyTypes } = useLookup('enemy-types', biome);
  const { data: environmentalContexts, isLoading: loadingContexts } = useLookup('environmental-contexts', biome);

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Enemy Type Hooks</Label>
        {loadingEnemyTypes ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <Controller
            name="enemyTypeHooks"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2">
                {enemyTypes?.map((item) => (
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

      <div className="space-y-2">
        <Label>Environmental Context</Label>
        {loadingContexts ? (
          <Skeleton className="h-10 w-full" />
        ) : (
          <Controller
            name="environmentalContext"
            control={control}
            render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Select context" />
                </SelectTrigger>
                <SelectContent>
                  {environmentalContexts?.map((item) => (
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
        <Label>Estimated Combat Difficulty</Label>
        <Controller
          name="estimatedCombatDifficulty"
          control={control}
          render={({ field }) => (
            <div className="flex items-center gap-4">
              <Slider
                min={1}
                max={5}
                step={1}
                value={[field.value || 1]}
                onValueChange={([value]) => field.onChange(value as 1 | 2 | 3 | 4 | 5)}
                className="flex-1"
              />
              <span className="w-8 text-center font-medium">{field.value || 1}</span>
            </div>
          )}
        />
      </div>
    </div>
  );
}
