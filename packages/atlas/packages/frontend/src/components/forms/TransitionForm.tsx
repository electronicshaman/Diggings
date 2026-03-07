import { useFormContext, Controller } from 'react-hook-form';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Act, ActNames } from '@atlas/shared';
import type { TransitionNodeMetadata } from '@atlas/shared';

const ACTS = [Act.Arrival, Act.Fever, Act.Blasphemy, Act.Unmaking];

export function TransitionForm() {
  const { control, register, watch, setValue } = useFormContext<TransitionNodeMetadata>();
  const worldStateShifts = watch('worldStateShifts') || [];

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label>Act Change Trigger (Optional)</Label>
        <Controller
          name="actChangeTrigger"
          control={control}
          render={({ field }) => (
            <Select
              value={field.value?.toString() ?? ''}
              onValueChange={(v) => field.onChange(v ? Number(v) as Act : undefined)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select act (optional)" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">None</SelectItem>
                {ACTS.map((act) => (
                  <SelectItem key={act} value={act.toString()}>
                    Act {act}: {ActNames[act]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        />
      </div>

      <div className="space-y-2">
        <Label>Narrative Summary</Label>
        <Textarea
          {...register('narrativeSummary')}
          placeholder="Summary of the transition narrative..."
          rows={3}
        />
      </div>

      <div className="space-y-2">
        <Label>World State Shifts</Label>
        <Input
          value={worldStateShifts.join(', ')}
          onChange={(e) => {
            const values = e.target.value
              .split(',')
              .map((v) => v.trim())
              .filter(Boolean);
            setValue('worldStateShifts', values);
          }}
          placeholder="Comma-separated values (e.g., darkness_spreads, gold_depleted)"
        />
        <p className="text-xs text-muted-foreground">Enter values separated by commas</p>
      </div>
    </div>
  );
}
