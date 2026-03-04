import { useFormContext, Controller } from 'react-hook-form';
import { useLookup } from '@/hooks/useConfig';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Skeleton } from '@/components/ui/skeleton';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type { PassageNodeMetadata } from '@node-gen-web/shared';

export function PassageForm() {
  const { control, watch, register } = useFormContext<PassageNodeMetadata>();
  const biome = watch('biome');

  const { data: travelEventHooks, isLoading: loadingEvents } = useLookup('travel-event-hooks', biome);
  const { data: environmentalStorytelling, isLoading: loadingStorytelling } = useLookup('environmental-storytelling', biome);

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Travel Event Hooks</Label>
        {loadingEvents ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <Controller
            name="travelEventHooks"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2">
                {travelEventHooks?.map((item) => (
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
        <Label>Environmental Storytelling</Label>
        {loadingStorytelling ? (
          <Skeleton className="h-10 w-full" />
        ) : (
          <Controller
            name="environmentalStorytelling"
            control={control}
            render={({ field }) => (
              <Select value={field.value} onValueChange={field.onChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Select storytelling" />
                </SelectTrigger>
                <SelectContent>
                  {environmentalStorytelling?.map((item) => (
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
        <Label>Resource Cost</Label>
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Type</Label>
            <Input {...register('resourceCost.type')} placeholder="Resource type" />
          </div>
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Amount</Label>
            <Input
              type="number"
              {...register('resourceCost.amount', { valueAsNumber: true })}
              placeholder="Amount"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
