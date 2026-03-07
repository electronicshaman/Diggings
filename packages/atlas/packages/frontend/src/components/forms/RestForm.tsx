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
import type { RestNodeMetadata } from '@atlas/shared';

const REST_TYPES = ['safe', 'risky', 'sacred'] as const;
const INTERRUPTION_CHANCES = ['none', 'low', 'medium', 'high'] as const;

export function RestForm() {
  const { control, watch } = useFormContext<RestNodeMetadata>();
  const biome = watch('biome');

  const { data: dreamHooks, isLoading } = useLookup('dream-hooks', biome);

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Rest Type</Label>
        <Controller
          name="restType"
          control={control}
          render={({ field }) => (
            <Select value={field.value} onValueChange={field.onChange}>
              <SelectTrigger>
                <SelectValue placeholder="Select type" />
              </SelectTrigger>
              <SelectContent>
                {REST_TYPES.map((type) => (
                  <SelectItem key={type} value={type}>
                    {type.charAt(0).toUpperCase() + type.slice(1)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        />
      </div>

      <div className="space-y-2">
        <Label>Interruption Chance</Label>
        <Controller
          name="interruptionChance"
          control={control}
          render={({ field }) => (
            <Select value={field.value} onValueChange={field.onChange}>
              <SelectTrigger>
                <SelectValue placeholder="Select chance" />
              </SelectTrigger>
              <SelectContent>
                {INTERRUPTION_CHANCES.map((chance) => (
                  <SelectItem key={chance} value={chance}>
                    {chance.charAt(0).toUpperCase() + chance.slice(1)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        />
      </div>

      <div className="space-y-2">
        <Label>Dream Hooks (Optional)</Label>
        {isLoading ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <Controller
            name="dreamHooks"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2">
                {dreamHooks?.map((item) => (
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
