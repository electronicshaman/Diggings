import { useFormContext, Controller } from 'react-hook-form';
import { useLookup } from '@/hooks/useConfig';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Skeleton } from '@/components/ui/skeleton';
import { Input } from '@/components/ui/input';
import type { StateCheckNodeMetadata } from '@node-gen-web/shared';

export function StateCheckForm() {
  const { control, watch, register } = useFormContext<StateCheckNodeMetadata>();
  const biome = watch('biome');

  const { data: conditionHooks, isLoading } = useLookup('condition-hooks', biome);

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Condition Hooks</Label>
        {isLoading ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <Controller
            name="conditionHooks"
            control={control}
            render={({ field }) => (
              <div className="grid grid-cols-2 gap-2">
                {conditionHooks?.map((item) => (
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
        <Label>Branch Targets</Label>
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Success Node ID</Label>
            <Input {...register('branchTargets.success')} placeholder="Node ID" />
          </div>
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Failure Node ID</Label>
            <Input {...register('branchTargets.failure')} placeholder="Node ID" />
          </div>
        </div>
      </div>
    </div>
  );
}
