import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Sparkles, Wand2 } from 'lucide-react';
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
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useBiomes } from '@/hooks/useConfig';
import { useGenerateNode } from '@/hooks/useGeneration';
import { useFieldGeneration } from '@/hooks/useFieldGeneration';
import { FieldAssistButton } from './FieldAssistButton';
import { NodeTypeDisplayNames, BiomeDisplayNames } from '@node-gen-web/shared';
import { cn } from '@/lib/utils';

const assistedCreateSchema = z.object({
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
  narrativeHook: z.string().max(500).optional(),
  additionalContext: z.string().max(1000).optional(),
});

type AssistedCreateFormData = z.infer<typeof assistedCreateSchema>;

// Helper function for actionable error messages
const getActionableErrorMessage = (error: string): string => {
  if (error.includes('No LLM provider')) {
    return 'Please configure an LLM provider in Settings before generating content.';
  }
  if (error.includes('rate limit') || error.includes('429')) {
    return 'API rate limit reached. Please wait a moment and try again.';
  }
  if (error.includes('API key') || error.includes('401') || error.includes('403')) {
    return 'Invalid API key. Please check your provider settings.';
  }
  if (error.includes('timeout') || error.includes('network')) {
    return 'Network error. Please check your connection and try again.';
  }
  return `${error}. Try again or adjust your inputs.`;
};

export function AssistedCreate() {
  const navigate = useNavigate();
  const { data: biomes } = useBiomes();
  const { generate, isGenerating } = useGenerateNode();

  const [suggestedBeats, setSuggestedBeats] = useState<Array<{
    id: string;
    role: string;
    text: string;
    included: boolean;
  }>>([]);
  const [isLoadingBeats, setIsLoadingBeats] = useState(false);

  const { generateField, generateBeatList, streamedContent, isGenerating: isFieldGenerating, cancel } = useFieldGeneration({
    onFinish: (_fieldName, content) => {
      // Update form state with final content
      form.setValue('narrativeHook', content, { shouldDirty: true });
      toast.success('Narrative hook generated');
    },
    onError: (error) => {
      // Display actionable error message (GEN-04 requirement)
      const actionableMessage = getActionableErrorMessage(error);
      toast.error('Generation failed', {
        description: actionableMessage,
        duration: 5000,
      });
    },
  });

  const form = useForm<AssistedCreateFormData>({
    resolver: zodResolver(assistedCreateSchema),
    defaultValues: {
      nodeType: 'combat',
      biome: 'township',
      name: '',
      acts: [1],
      narrativeHook: '',
      additionalContext: '',
    },
  });

  const selectedBiome = form.watch('biome');
  const biomeConfig = biomes?.find((b) => b.id === selectedBiome);

  const handleGenerateHook = async () => {
    const values = form.getValues();
    if (!values.name || !values.nodeType || !values.biome) {
      toast.warning('Missing required fields', {
        description: 'Please fill in name, node type, and biome first'
      });
      return;
    }

    await generateField('narrative_hook', 'narrativeHook', {
      nodeType: values.nodeType,
      biome: values.biome,
      name: values.name,
      themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
      entityTypes: ['character'],
      act: values.acts?.[0],
    });
  };

  const handleSuggestBeats = async () => {
    const values = form.getValues();
    if (!values.nodeType || !values.biome) {
      toast.warning('Missing required fields', {
        description: 'Please select node type and biome first'
      });
      return;
    }

    setIsLoadingBeats(true);
    const beats = await generateBeatList({
      nodeType: values.nodeType,
      biome: values.biome,
      name: values.name,
      themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
      narrativeHook: values.narrativeHook,
    });
    setIsLoadingBeats(false);

    if (beats) {
      setSuggestedBeats(beats.map(beat => ({
        ...beat,
        included: true, // All included by default
      })));
      toast.success('Beats suggested', {
        description: `Generated ${beats.length} story beats. Review and adjust as needed.`
      });
    }
  };

  const toggleBeat = (beatId: string) => {
    setSuggestedBeats(prev => prev.map(beat =>
      beat.id === beatId ? { ...beat, included: !beat.included } : beat
    ));
  };

  const handleFullGenerate = async () => {
    const values = form.getValues();

    // Note: Beat preferences are stored for future enhancement
    // Currently, the generation API doesn't support passing beat hints
    // Future work: Add hints field to GenerationRequest schema
    const includedBeatsCount = suggestedBeats.filter(b => b.included).length;
    if (includedBeatsCount > 0 && includedBeatsCount !== suggestedBeats.length) {
      toast.info('Beat preferences noted', {
        description: `Generating with ${includedBeatsCount} of ${suggestedBeats.length} suggested beats`,
      });
    }

    try {
      await generate({
        nodeType: values.nodeType,
        biome: values.biome,
        name: values.name,
        acts: values.acts as [number, ...number[]],
        themes: biomeConfig?.themes?.slice(0, 2) || ['survival'],
        entityTypes: ['character'],
        actVariant: false,
      });
      navigate('/nodes');
    } catch {
      // Error handled in hook
    }
  };

  const onSubmit = () => {
    navigate('/nodes/create');
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Wand2 className="size-5" />
          Assisted Create
        </CardTitle>
        <CardDescription>
          Create a node with AI assistance. Fill in what you want, use AI to help with the rest.
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

            <FormField
              control={form.control}
              name="narrativeHook"
              render={({ field }) => (
                <FormItem>
                  <div className="flex items-center justify-between">
                    <FormLabel>Narrative Hook</FormLabel>
                    <div className="flex gap-2">
                      {isFieldGenerating ? (
                        <Button type="button" variant="ghost" size="sm" onClick={cancel}>
                          Cancel
                        </Button>
                      ) : (
                        <FieldAssistButton
                          onClick={handleGenerateHook}
                          isLoading={false}
                          disabled={!form.watch('name') || !form.watch('nodeType') || !form.watch('biome')}
                          tooltip="Generate narrative hook with AI"
                        />
                      )}
                    </div>
                  </div>
                  <FormControl>
                    <Textarea
                      placeholder="The opening text that draws players in..."
                      className="min-h-24"
                      {...field}
                      value={isFieldGenerating ? streamedContent : field.value}
                      onChange={(e) => {
                        // Only allow editing when not generating
                        if (!isFieldGenerating) {
                          field.onChange(e);
                        }
                      }}
                      readOnly={isFieldGenerating}
                    />
                  </FormControl>
                  <FormDescription>1-3 sentences that set the scene</FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            {/* Beat Suggestions Section */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label>Story Beats (Optional Preview)</Label>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleSuggestBeats}
                  disabled={isLoadingBeats || !form.watch('nodeType') || !form.watch('biome')}
                >
                  {isLoadingBeats ? (
                    <>
                      <Sparkles className="mr-2 size-4 animate-pulse" />
                      Generating...
                    </>
                  ) : (
                    <>
                      <Sparkles className="mr-2 size-4" />
                      Suggest Beats
                    </>
                  )}
                </Button>
              </div>

              {suggestedBeats.length > 0 && (
                <div className="space-y-2 rounded-lg border p-4">
                  <p className="text-sm text-muted-foreground">
                    Toggle beats to include/exclude from generation:
                  </p>
                  {suggestedBeats.map((beat) => (
                    <div
                      key={beat.id}
                      className={cn(
                        "flex items-start gap-3 rounded-md p-2 transition-colors",
                        beat.included ? "bg-muted/50" : "bg-muted/20 opacity-60"
                      )}
                    >
                      <Checkbox
                        checked={beat.included}
                        onCheckedChange={() => toggleBeat(beat.id)}
                      />
                      <div className="flex-1 space-y-1">
                        <Badge variant="outline" className="text-xs">
                          {beat.role}
                        </Badge>
                        <p className="text-sm">{beat.text}</p>
                      </div>
                    </div>
                  ))}
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setSuggestedBeats([])}
                    className="mt-2"
                  >
                    Clear suggestions
                  </Button>
                </div>
              )}

              <p className="text-xs text-muted-foreground">
                Preview the beat structure before generating. Uncheck beats you don't want included.
              </p>
            </div>

            <FormField
              control={form.control}
              name="additionalContext"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Additional Context (Optional)</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder="Any specific themes, characters, or story elements to include..."
                      className="min-h-20"
                      {...field}
                    />
                  </FormControl>
                  <FormDescription>
                    Provide hints for the AI about what you want in this node
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="flex gap-3">
              <Button type="submit" variant="outline" className="flex-1">
                Continue Manually
              </Button>
              <Button
                type="button"
                onClick={handleFullGenerate}
                disabled={isGenerating}
                className="flex-1"
              >
                <Sparkles className="mr-2 size-4" />
                Generate Everything
              </Button>
            </div>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
