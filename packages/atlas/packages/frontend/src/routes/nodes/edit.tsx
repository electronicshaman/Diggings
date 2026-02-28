import { useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { useForm, FormProvider, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { ArrowLeft } from 'lucide-react';
import { toast } from 'sonner';
import { errorToast } from '@/lib/toast-utils';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Checkbox } from '@/components/ui/checkbox';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useNode } from '@/hooks/useNodes';
import { useUpdateNode } from '@/hooks/useNodeMutations';
import {
  CombatForm,
  ChoiceForm,
  TradeForm,
  RestForm,
  PassageForm,
  StateCheckForm,
  TransitionForm,
} from '@/components/forms';
import {
  NodeType,
  NodeTypeDisplayNames,
  ALL_BIOMES,
  BiomeDisplayNames,
  ALL_ACTS,
  ActNames,
  Biome,
  type AnyNodeMetadata,
} from '@node-gen-web/shared';

const typeSpecificSchema = z.object({
  enemyTypeHooks: z.array(z.string()).optional(),
  environmentalContext: z.string().optional(),
  estimatedCombatDifficulty: z.number().min(1).max(5).optional(),
  consequenceHooks: z.array(z.string()).optional(),
  dilemmaType: z.enum(['moral', 'practical', 'survival']).optional(),
  traderArchetype: z.string().optional(),
  pricingHooks: z.array(z.string()).optional(),
  restType: z.enum(['safe', 'risky', 'sacred']).optional(),
  interruptionChance: z.enum(['none', 'low', 'medium', 'high']).optional(),
  dreamHooks: z.array(z.string()).optional(),
  travelEventHooks: z.array(z.string()).optional(),
  environmentalStorytelling: z.string().optional(),
  resourceCost: z.object({
    type: z.string(),
    amount: z.number(),
    optional: z.boolean().optional(),
  }).optional(),
  conditionHooks: z.array(z.string()).optional(),
  branchTargets: z.object({
    success: z.string(),
    failure: z.string(),
  }).optional(),
  actChangeTrigger: z.number().optional(),
  narrativeSummary: z.string().optional(),
  worldStateShifts: z.array(z.string()).optional(),
});

const editNodeSchema = z.object({
  name: z.string().min(3, 'Name must be at least 3 characters'),
  biome: z.nativeEnum(Biome),
  acts: z.array(z.number()).min(1, 'Select at least one act'),
  isReplaceable: z.boolean(),
  replacementTags: z.string(),
  themes: z.string(),
  entityTypes: z.string(),
}).merge(typeSpecificSchema);

type EditNodeFormData = z.infer<typeof editNodeSchema>;

function LoadingSkeleton() {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Skeleton className="h-4 w-24" />
      </div>
      <div className="space-y-2">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-4 w-48" />
      </div>
      <Card>
        <CardContent className="pt-6 space-y-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="grid grid-cols-3 gap-4">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-10 w-full col-span-2" />
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

function TypeSpecificSection({ type }: { type: NodeType }) {
  switch (type) {
    case NodeType.Combat:
      return <CombatForm />;
    case NodeType.Choice:
      return <ChoiceForm />;
    case NodeType.Trade:
      return <TradeForm />;
    case NodeType.Rest:
      return <RestForm />;
    case NodeType.Passage:
      return <PassageForm />;
    case NodeType.StateCheck:
      return <StateCheckForm />;
    case NodeType.Transition:
      return <TransitionForm />;
    default:
      return null;
  }
}

export function NodeEditPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: node, isLoading, error } = useNode(id);
  const updateNode = useUpdateNode();

  const methods = useForm<EditNodeFormData>({
    resolver: zodResolver(editNodeSchema),
    defaultValues: {
      name: '',
      biome: Biome.TheBush,
      acts: [],
      isReplaceable: true,
      replacementTags: '',
      themes: '',
      entityTypes: '',
    },
  });

  const { register, handleSubmit, setValue, watch, reset, formState: { errors, isDirty } } = methods;
  const selectedActs = watch('acts');
  const isReplaceable = watch('isReplaceable');

  useEffect(() => {
    if (node) {
      reset({
        name: node.name,
        biome: node.biome,
        acts: node.acts,
        isReplaceable: node.isReplaceable,
        replacementTags: node.replacementTags?.join(', ') || '',
        themes: node.themes?.join(', ') || '',
        entityTypes: node.entityTypes?.join(', ') || '',
        ...getTypeSpecificDefaults(node),
      });
    }
  }, [node, reset]);

  const handleActToggle = (act: number, checked: boolean) => {
    const current = selectedActs || [];
    if (checked) {
      setValue('acts', [...current, act], { shouldDirty: true });
    } else {
      setValue('acts', current.filter((a) => a !== act), { shouldDirty: true });
    }
  };

  const parseCommaSeparated = (str: string) =>
    str.split(',').map((s) => s.trim()).filter(Boolean);

  const onSubmit = async (data: EditNodeFormData) => {
    if (!id || !node) return;

    const baseData = {
      name: data.name,
      biome: data.biome,
      acts: data.acts,
      isReplaceable: data.isReplaceable,
      replacementTags: parseCommaSeparated(data.replacementTags),
      themes: parseCommaSeparated(data.themes),
      entityTypes: parseCommaSeparated(data.entityTypes),
    };

    const typeData = getTypeSpecificData(node.type, data);

    try {
      await updateNode.mutateAsync({
        nodeId: id,
        data: { ...baseData, ...typeData },
      });
      toast.success('Node updated successfully');
      navigate(`/nodes/${id}`);
    } catch (err) {
      errorToast(err instanceof Error ? err.message : 'Failed to update node');
    }
  };

  if (isLoading) {
    return <LoadingSkeleton />;
  }

  if (error || !node) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Link
            to="/nodes"
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="size-4" />
            Back to nodes
          </Link>
        </div>
        <Card>
          <CardHeader>
            <CardTitle className="text-destructive">Node Not Found</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground">
              {error instanceof Error ? error.message : `Could not find node with ID: ${id}`}
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <div className="flex items-center gap-4">
          <Link
            to={`/nodes/${id}`}
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="size-4" />
            Back to node
          </Link>
        </div>

        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Edit Node</h1>
            <p className="text-muted-foreground">
              Editing {NodeTypeDisplayNames[node.type]}: {node.name}
            </p>
          </div>
          <div className="flex gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => navigate(`/nodes/${id}`)}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={!isDirty || updateNode.isPending}>
              {updateNode.isPending ? 'Saving...' : 'Save Changes'}
            </Button>
          </div>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Base Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="id">Node ID</Label>
                <Input id="id" value={node.id} disabled className="bg-muted" />
                <p className="text-xs text-muted-foreground">ID cannot be changed</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="name">Name *</Label>
                <Input id="name" placeholder="Node name" {...register('name')} />
                {errors.name && (
                  <p className="text-sm text-destructive">{errors.name.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="type">Type</Label>
                <Input
                  id="type"
                  value={NodeTypeDisplayNames[node.type]}
                  disabled
                  className="bg-muted"
                />
                <p className="text-xs text-muted-foreground">Type cannot be changed</p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="biome">Biome *</Label>
                <Controller
                  name="biome"
                  control={methods.control}
                  render={({ field }) => (
                    <Select value={field.value} onValueChange={(value) => field.onChange(value as Biome)}>
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
                  )}
                />
                {errors.biome && (
                  <p className="text-sm text-destructive">{errors.biome.message}</p>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <Label>Acts *</Label>
              <div className="flex flex-wrap gap-4">
                {ALL_ACTS.map((act) => (
                  <div key={act} className="flex items-center gap-2">
                    <Checkbox
                      id={`act-${act}`}
                      checked={selectedActs?.includes(act)}
                      onCheckedChange={(checked) => handleActToggle(act, checked as boolean)}
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

            <div className="flex items-center gap-3">
              <Switch
                id="isReplaceable"
                checked={isReplaceable}
                onCheckedChange={(checked) => setValue('isReplaceable', checked, { shouldDirty: true })}
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
                <Input id="themes" placeholder="theme1, theme2" {...register('themes')} />
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
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{NodeTypeDisplayNames[node.type]} Properties</CardTitle>
          </CardHeader>
          <CardContent>
            <TypeSpecificSection type={node.type} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Eligibility</CardTitle>
          </CardHeader>
          <CardContent>
            {node.eligibility ? (
              <pre className="text-sm bg-muted p-4 rounded-lg overflow-auto max-h-[300px]">
                {JSON.stringify(node.eligibility, null, 2)}
              </pre>
            ) : (
              <p className="text-muted-foreground">No eligibility criteria defined</p>
            )}
            <p className="text-xs text-muted-foreground mt-2">
              Eligibility editing coming in a future update
            </p>
          </CardContent>
        </Card>
      </form>
    </FormProvider>
  );
}

function getTypeSpecificDefaults(node: AnyNodeMetadata): Partial<EditNodeFormData> {
  switch (node.type) {
    case NodeType.Combat:
      return {
        enemyTypeHooks: node.enemyTypeHooks,
        environmentalContext: node.environmentalContext,
        estimatedCombatDifficulty: node.estimatedCombatDifficulty,
      };
    case NodeType.Choice:
      return {
        consequenceHooks: node.consequenceHooks,
        dilemmaType: node.dilemmaType,
      };
    case NodeType.Trade:
      return {
        traderArchetype: node.traderArchetype,
        pricingHooks: node.pricingHooks,
      };
    case NodeType.Rest:
      return {
        restType: node.restType,
        interruptionChance: node.interruptionChance,
        dreamHooks: node.dreamHooks,
      };
    case NodeType.Passage:
      return {
        travelEventHooks: node.travelEventHooks,
        environmentalStorytelling: node.environmentalStorytelling,
        resourceCost: node.resourceCost,
      };
    case NodeType.StateCheck:
      return {
        conditionHooks: node.conditionHooks,
        branchTargets: node.branchTargets,
      };
    case NodeType.Transition:
      return {
        actChangeTrigger: node.actChangeTrigger,
        narrativeSummary: node.narrativeSummary,
        worldStateShifts: node.worldStateShifts,
      };
    default:
      return {};
  }
}

function getTypeSpecificData(type: NodeType, data: EditNodeFormData): Partial<AnyNodeMetadata> {
  switch (type) {
    case NodeType.Combat:
      return {
        enemyTypeHooks: data.enemyTypeHooks || [],
        environmentalContext: data.environmentalContext || '',
        estimatedCombatDifficulty: (data.estimatedCombatDifficulty || 1) as 1 | 2 | 3 | 4 | 5,
      };
    case NodeType.Choice:
      return {
        consequenceHooks: data.consequenceHooks || [],
        dilemmaType: data.dilemmaType,
      };
    case NodeType.Trade:
      return {
        traderArchetype: data.traderArchetype || '',
        pricingHooks: data.pricingHooks || [],
      };
    case NodeType.Rest:
      return {
        restType: data.restType,
        interruptionChance: data.interruptionChance,
        dreamHooks: data.dreamHooks,
      };
    case NodeType.Passage:
      return {
        travelEventHooks: data.travelEventHooks || [],
        environmentalStorytelling: data.environmentalStorytelling || '',
        resourceCost: data.resourceCost,
      };
    case NodeType.StateCheck:
      return {
        conditionHooks: data.conditionHooks || [],
        branchTargets: data.branchTargets,
      };
    case NodeType.Transition:
      return {
        actChangeTrigger: data.actChangeTrigger,
        narrativeSummary: data.narrativeSummary || '',
        worldStateShifts: data.worldStateShifts || [],
      };
    default:
      return {};
  }
}
