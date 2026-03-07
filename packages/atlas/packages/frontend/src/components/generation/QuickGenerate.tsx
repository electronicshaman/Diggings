import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Sparkles } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { GenerationProgress } from './GenerationProgress';
import { useGenerateNode } from '@/hooks/useGeneration';
import { useCreateNode } from '@/hooks/useNodeMutations';
import { useBiomes } from '@/hooks/useConfig';
import { NodeTypeDisplayNames, BiomeDisplayNames, NodeType, Biome } from '@atlas/shared';
import type { GenerationRequest, AnyNodeMetadata } from '@atlas/shared';

const quickGenerateSchema = z.object({
  nodeType: z.enum(['combat', 'choice', 'trade', 'rest', 'passage', 'state_check', 'transition']),
  biome: z.enum([
    'township',
    'the_diggings',
    'the_bush',
    'the_mines',
    'the_waste',
    'the_scar',
    'sacred_site',
    'the_river',
  ]),
  name: z.string().min(1, 'Name is required').max(255),
  acts: z.array(z.number()).min(1, 'Select at least one act'),
});

type QuickGenerateFormData = z.infer<typeof quickGenerateSchema>;

export function QuickGenerate() {
  const navigate = useNavigate();
  const { state, generate, abort, reset, isGenerating } = useGenerateNode();
  const createNodeMutation = useCreateNode();
  const { data: biomes } = useBiomes();

  const form = useForm<QuickGenerateFormData>({
    resolver: zodResolver(quickGenerateSchema),
    defaultValues: {
      nodeType: 'combat',
      biome: 'township',
      name: '',
      acts: [1],
    },
  });

  const selectedBiome = form.watch('biome');
  const biomeConfig = biomes?.find((b) => b.id === selectedBiome);

  // Cleanup streaming on unmount
  useEffect(() => {
    return () => {
      // Abort any in-flight stream when navigating away
      abort();
    };
  }, [abort]);

  const onSubmit = async (data: QuickGenerateFormData) => {
    const request: GenerationRequest = {
      nodeType: data.nodeType,
      biome: data.biome,
      name: data.name,
      acts: data.acts as [number, ...number[]],
      themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
      entityTypes: ['character'],
      actVariant: false,
    };

    try {
      await generate(request);
    } catch {
      // Error handled in state
    }
  };

  const handleRetry = () => {
    // Reset state but preserve form values
    reset();
    // Re-submit with current form values
    form.handleSubmit(onSubmit)();
  };

  const handleCancel = () => {
    abort();
    toast.info('Generation cancelled');
  };

  const handleAccept = async () => {
    if (!state.content) return;

    try {
      // Build node data from form values + generated content
      const formValues = form.getValues();
      const nodeType = formValues.nodeType as NodeType;
      const biome = formValues.biome as Biome;

      // Build base node data
      const baseData = {
        type: nodeType,
        biome,
        name: formValues.name,
        acts: formValues.acts as [number, ...number[]],
        themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
        entityTypes: ['character'],
        content: state.content,
        criticScore: state.criticScore,
        isReplaceable: true,
        replacementTags: [],
        actVariant: false,
      };

      // Add type-specific required fields with defaults
      let nodeData: Omit<AnyNodeMetadata, 'id'> = baseData as unknown as Omit<AnyNodeMetadata, 'id'>;

      if (nodeType === NodeType.Combat) {
        nodeData = {
          ...baseData,
          enemyTypeHooks: ['generic_enemy'],
          environmentalContext: 'Standard combat environment',
          estimatedCombatDifficulty: 3 as const,
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      } else if (nodeType === NodeType.Choice) {
        nodeData = {
          ...baseData,
          consequenceHooks: ['generic_consequence'],
          dilemmaType: 'practical' as const,
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      } else if (nodeType === NodeType.Trade) {
        nodeData = {
          ...baseData,
          traderArchetype: 'general_merchant',
          pricingHooks: ['standard_pricing'],
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      } else if (nodeType === NodeType.Rest) {
        nodeData = {
          ...baseData,
          restType: 'safe' as const,
          interruptionChance: 'low' as const,
          dreamHooks: [],
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      } else if (nodeType === NodeType.Passage) {
        nodeData = {
          ...baseData,
          travelEventHooks: ['travel_event'],
          environmentalStorytelling: 'Standard travel passage',
          resourceCost: { type: 'time', amount: 1 },
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      } else if (nodeType === NodeType.StateCheck) {
        nodeData = {
          ...baseData,
          conditionHooks: ['state_condition'],
          branchTargets: { success: 'success_node', failure: 'failure_node' },
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      } else if (nodeType === NodeType.Transition) {
        nodeData = {
          ...baseData,
          narrativeSummary: 'Act transition',
          worldStateShifts: ['narrative_progression'],
        } as unknown as Omit<AnyNodeMetadata, 'id'>;
      }

      const savedNode = await createNodeMutation.mutateAsync(nodeData);

      toast.success(`${savedNode.name} has been created.`);

      // Navigate to node detail
      navigate(`/nodes/${savedNode.id}`);

      // Reset form and state
      reset();
      form.reset();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to save node');
    }
  };

  if (state.stage !== 'idle') {
    return (
      <GenerationProgress
        state={state}
        onCancel={handleCancel}
        onRetry={handleRetry}
        onAccept={handleAccept}
        showContent
        threshold={70}
      />
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Sparkles className="size-5" />
          Quick Generate
        </CardTitle>
        <CardDescription>
          Generate a complete node with minimal input. Just provide the basics and AI will handle
          the rest.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid gap-6 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="nodeType"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Node Type</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select type" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {Object.entries(NodeTypeDisplayNames).map(([key, label]) => (
                          <SelectItem key={key} value={key}>
                            {label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="biome"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Biome</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select biome" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {Object.entries(BiomeDisplayNames).map(([key, label]) => (
                          <SelectItem key={key} value={key}>
                            {label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Node Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Enter a name for this node..." {...field} />
                  </FormControl>
                  <FormDescription>A short, descriptive name for the node</FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="acts"
              render={() => (
                <FormItem>
                  <FormLabel>Acts</FormLabel>
                  <FormDescription>Select which acts this node can appear in</FormDescription>
                  <div className="flex gap-4 pt-2">
                    {[1, 2, 3, 4].map((act) => (
                      <FormField
                        key={act}
                        control={form.control}
                        name="acts"
                        render={({ field }) => (
                          <FormItem className="flex items-center gap-2">
                            <FormControl>
                              <Checkbox
                                checked={field.value?.includes(act)}
                                onCheckedChange={(checked) => {
                                  const current = field.value || [];
                                  if (checked) {
                                    field.onChange([...current, act]);
                                  } else {
                                    field.onChange(current.filter((v: number) => v !== act));
                                  }
                                }}
                              />
                            </FormControl>
                            <FormLabel className="!mt-0 font-normal">Act {act}</FormLabel>
                          </FormItem>
                        )}
                      />
                    ))}
                  </div>
                  <FormMessage />
                </FormItem>
              )}
            />

            <Button type="submit" disabled={isGenerating} className="w-full">
              <Sparkles className="mr-2 size-4" />
              Generate Node
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
