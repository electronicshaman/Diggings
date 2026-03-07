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
import type { ChoiceNodeMetadata } from '@atlas/shared';

const DILEMMA_TYPES = ['moral', 'practical', 'survival'] as const;

export function ChoiceForm() {
  const { control, watch } = useFormContext<ChoiceNodeMetadata>();
  const biome = watch('biome');

  const { data: consequenceHooks, isLoading } = useLookup('consequence-hooks', biome);

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Consequence Hooks</Label>
        {isLoading ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <Controller
            name="consequenceHooks"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2">
                {consequenceHooks?.map((item) => (
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
        <Label>Dilemma Type</Label>
        <Controller
          name="dilemmaType"
          control={control}
          render={({ field }) => (
            <Select value={field.value} onValueChange={field.onChange}>
              <SelectTrigger>
                <SelectValue placeholder="Select type" />
              </SelectTrigger>
              <SelectContent>
                {DILEMMA_TYPES.map((type) => (
                  <SelectItem key={type} value={type}>
                    {type.charAt(0).toUpperCase() + type.slice(1)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        />
      </div>
    </div>
  );
}
