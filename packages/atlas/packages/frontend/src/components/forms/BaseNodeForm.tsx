import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  ALL_BIOMES,
  BiomeDisplayNames,
  ALL_ACTS,
  ActNames,
  Biome,
} from '@node-gen-web/shared';
import { useFormStore } from '@/store/form-store';

const baseNodeSchema = z.object({
  id: z
    .string()
    .optional()
    .refine((val) => !val || /^[A-Z_]+_\d{3}$/.test(val), {
      message: 'ID must match pattern BIOME_TYPE_NNN (e.g., BUSH_COMBAT_001)',
    }),
  name: z.string().min(3, 'Name must be at least 3 characters'),
  biome: z.nativeEnum(Biome),
  acts: z.array(z.number()).min(1, 'Select at least one act'),
  isReplaceable: z.boolean(),
  replacementTags: z.string(),
  themes: z.string(),
  entityTypes: z.string(),
});

type BaseNodeFormData = z.infer<typeof baseNodeSchema>;

export function BaseNodeForm() {
  const { formData, setFormData, nextStep, prevStep } = useFormStore();

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<BaseNodeFormData>({
    resolver: zodResolver(baseNodeSchema),
    defaultValues: {
      id: formData.id || '',
      name: formData.name || '',
      biome: formData.biome,
      acts: formData.acts || [],
      isReplaceable: formData.isReplaceable ?? true,
      replacementTags: formData.replacementTags?.join(', ') || '',
      themes: formData.themes?.join(', ') || '',
      entityTypes: formData.entityTypes?.join(', ') || '',
    },
  });

  const selectedActs = watch('acts');
  const isReplaceable = watch('isReplaceable');
  const selectedBiome = watch('biome');

  const onSubmit = (data: BaseNodeFormData) => {
    const parseCommaSeparated = (str: string) =>
      str
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);

    setFormData({
      id: data.id || undefined,
      name: data.name,
      biome: data.biome,
      acts: data.acts,
      isReplaceable: data.isReplaceable,
      replacementTags: parseCommaSeparated(data.replacementTags),
      themes: parseCommaSeparated(data.themes),
      entityTypes: parseCommaSeparated(data.entityTypes),
    });
    nextStep();
  };

  const handleActToggle = (act: number, checked: boolean) => {
    const current = selectedActs || [];
    if (checked) {
      setValue('acts', [...current, act]);
    } else {
      setValue(
        'acts',
        current.filter((a) => a !== act)
      );
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold">Base Node Properties</h2>
        <p className="text-sm text-muted-foreground">
          Configure the core properties for this node. Need help? Try the{' '}
          <a href="/generate" className="underline underline-offset-4 hover:text-foreground">
            AI Generation
          </a>{' '}
          page for assistance.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="id">Node ID (optional)</Label>
          <Input
            id="id"
            placeholder="BIOME_TYPE_001"
            {...register('id')}
          />
          {errors.id && (
            <p className="text-sm text-destructive">{errors.id.message}</p>
          )}
          <p className="text-xs text-muted-foreground">
            Leave empty to auto-generate
          </p>
        </div>

        <div className="space-y-2">
          <Label htmlFor="name">Name *</Label>
          <Input
            id="name"
            placeholder="Node name"
            {...register('name')}
          />
          {errors.name && (
            <p className="text-sm text-destructive">{errors.name.message}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="biome">Biome *</Label>
          <Select
            value={selectedBiome}
            onValueChange={(value) => setValue('biome', value as Biome)}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select biome" />
            </SelectTrigger>
            <SelectContent>
              {ALL_BIOMES.map((biome) => (
                <SelectItem key={biome} value={biome}>
                  {BiomeDisplayNames[biome]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.biome && (
            <p className="text-sm text-destructive">{errors.biome.message}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label>Acts *</Label>
          <div className="flex flex-wrap gap-4">
            {ALL_ACTS.map((act) => (
              <div key={act} className="flex items-center gap-2">
                <Checkbox
                  id={`act-${act}`}
                  checked={selectedActs?.includes(act)}
                  onCheckedChange={(checked) =>
                    handleActToggle(act, checked as boolean)
                  }
                />
                <Label htmlFor={`act-${act}`} className="text-sm font-normal">
                  {act}: {ActNames[act]}
                </Label>
              </div>
            ))}
          </div>
          {errors.acts && (
            <p className="text-sm text-destructive">{errors.acts.message}</p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <Switch
          id="isReplaceable"
          checked={isReplaceable}
          onCheckedChange={(checked) => setValue('isReplaceable', checked)}
        />
        <Label htmlFor="isReplaceable">Is Replaceable</Label>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="space-y-2">
          <Label htmlFor="replacementTags">Replacement Tags</Label>
          <Input
            id="replacementTags"
            placeholder="tag1, tag2, tag3"
            {...register('replacementTags')}
          />
          <p className="text-xs text-muted-foreground">Comma-separated</p>
        </div>

        <div className="space-y-2">
          <Label htmlFor="themes">Themes</Label>
          <Input
            id="themes"
            placeholder="theme1, theme2"
            {...register('themes')}
          />
          <p className="text-xs text-muted-foreground">Comma-separated</p>
        </div>

        <div className="space-y-2">
          <Label htmlFor="entityTypes">Entity Types</Label>
          <Input
            id="entityTypes"
            placeholder="type1, type2"
            {...register('entityTypes')}
          />
          <p className="text-xs text-muted-foreground">Comma-separated</p>
        </div>
      </div>

      <div className="flex justify-between pt-4">
        <Button type="button" variant="outline" onClick={prevStep}>
          Back
        </Button>
        <Button type="submit">Next</Button>
      </div>
    </form>
  );
}
