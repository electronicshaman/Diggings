import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Save, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Slider } from '@/components/ui/slider';
import { useUpdateGenerationSettings } from '@/hooks/useAdvancedConfig';
import {
  GenerationSettingsUpdateSchema,
  type GenerationSettings,
  type GenerationSettingsUpdate,
} from '@atlas/shared';

interface GenerationSettingsFormProps {
  settings: GenerationSettings;
}

type FormData = GenerationSettingsUpdate;

export function GenerationSettingsForm({ settings }: GenerationSettingsFormProps) {
  const updateSettings = useUpdateGenerationSettings();

  const {
    handleSubmit,
    setValue,
    watch,
    formState: { isSubmitting, isDirty },
  } = useForm<FormData>({
    resolver: zodResolver(GenerationSettingsUpdateSchema),
    defaultValues: {
      batchSize: settings.batchSize,
      criticThreshold: settings.criticThreshold,
      enableCriticStage: settings.enableCriticStage,
      defaultTemperature: settings.defaultTemperature,
      maxRetries: settings.maxRetries,
    },
  });

  const batchSize = watch('batchSize') ?? settings.batchSize;
  const criticThreshold = watch('criticThreshold') ?? settings.criticThreshold;
  const enableCriticStage = watch('enableCriticStage') ?? settings.enableCriticStage;
  const defaultTemperature = watch('defaultTemperature') ?? settings.defaultTemperature;
  const maxRetries = watch('maxRetries') ?? settings.maxRetries;

  const onSubmit = async (data: FormData) => {
    try {
      await updateSettings.mutateAsync(data);
      toast.success('Generation settings updated successfully');
    } catch (error) {
      toast.error(
        `Failed to update settings: ${
          error instanceof Error ? error.message : 'Unknown error'
        }`
      );
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold">Generation Settings</h2>
        <p className="text-sm text-muted-foreground">
          Configure default settings for AI content generation.
        </p>
      </div>

      <div className="space-y-6 rounded-lg border p-6">
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="batchSize">Batch Size: {batchSize}</Label>
            <span className="text-sm text-muted-foreground">
              {batchSize} {batchSize === 1 ? 'node' : 'nodes'} per batch
            </span>
          </div>
          <Slider
            id="batchSize"
            min={1}
            max={20}
            step={1}
            value={[batchSize]}
            onValueChange={(value) => setValue('batchSize', value[0], { shouldDirty: true })}
          />
          <p className="text-xs text-muted-foreground">
            Number of nodes to generate in parallel during bulk generation.
          </p>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="criticThreshold">Critic Threshold: {criticThreshold}</Label>
            <span className="text-sm text-muted-foreground">
              {criticThreshold}% minimum score
            </span>
          </div>
          <Slider
            id="criticThreshold"
            min={0}
            max={100}
            step={5}
            value={[criticThreshold]}
            onValueChange={(value) => setValue('criticThreshold', value[0], { shouldDirty: true })}
          />
          <p className="text-xs text-muted-foreground">
            Minimum quality score required for generated content to pass the critic stage.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Checkbox
            id="enableCriticStage"
            checked={enableCriticStage}
            onCheckedChange={(checked) =>
              setValue('enableCriticStage', checked as boolean, { shouldDirty: true })
            }
          />
          <div className="space-y-0.5">
            <Label htmlFor="enableCriticStage" className="text-sm font-normal">
              Enable Critic Stage
            </Label>
            <p className="text-xs text-muted-foreground">
              When enabled, generated content will be evaluated and may be regenerated if it
              does not meet quality standards.
            </p>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="defaultTemperature">Default Temperature: {defaultTemperature}</Label>
            <span className="text-sm text-muted-foreground">
              {(defaultTemperature / 100).toFixed(2)}
            </span>
          </div>
          <Slider
            id="defaultTemperature"
            min={0}
            max={100}
            step={1}
            value={[defaultTemperature]}
            onValueChange={(value) => setValue('defaultTemperature', value[0], { shouldDirty: true })}
          />
          <p className="text-xs text-muted-foreground">
            Default temperature for generation. Lower values produce more focused output, higher
            values produce more creative output.
          </p>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="maxRetries">Max Retries: {maxRetries}</Label>
            <span className="text-sm text-muted-foreground">
              {maxRetries} {maxRetries === 1 ? 'attempt' : 'attempts'}
            </span>
          </div>
          <Slider
            id="maxRetries"
            min={0}
            max={10}
            step={1}
            value={[maxRetries]}
            onValueChange={(value) => setValue('maxRetries', value[0], { shouldDirty: true })}
          />
          <p className="text-xs text-muted-foreground">
            Maximum number of times to retry generation if it fails or doesn't meet quality
            standards.
          </p>
        </div>
      </div>

      <div className="flex justify-end">
        <Button type="submit" disabled={isSubmitting || !isDirty}>
          {isSubmitting ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Saving...
            </>
          ) : (
            <>
              <Save className="mr-2 h-4 w-4" />
              Save Settings
            </>
          )}
        </Button>
      </div>
    </form>
  );
}
