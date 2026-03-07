import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Boxes, Play, Pause } from 'lucide-react';
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
import { Switch } from '@/components/ui/switch';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { DistributionGapChart } from './DistributionGapChart';
import { NodeTypeDisplayNames, BiomeDisplayNames, type Biome, type NodeType } from '@node-gen-web/shared';

const bulkGenerateSchema = z.object({
  biome: z.string().optional(),
  nodeType: z.string().optional(),
  count: z.number().int().min(1).max(50).optional(),
  fillGaps: z.boolean().default(true),
});

type BulkGenerateFormData = z.infer<typeof bulkGenerateSchema>;

interface BulkGenerationProgress {
  status: 'idle' | 'running' | 'paused' | 'completed' | 'error';
  total: number;
  completed: number;
  failed: number;
  currentNode?: string;
  errors: string[];
}

export function BulkGenerate() {
  const [progress, setProgress] = useState<BulkGenerationProgress>({
    status: 'idle',
    total: 0,
    completed: 0,
    failed: 0,
    errors: [],
  });

  const form = useForm<BulkGenerateFormData>({
    resolver: zodResolver(bulkGenerateSchema),
    defaultValues: {
      fillGaps: true,
    },
  });

  const fillGaps = form.watch('fillGaps');

  const handleGapSelect = (biome: Biome, nodeType: NodeType, gap: number) => {
    form.setValue('biome', biome);
    form.setValue('nodeType', nodeType);
    form.setValue('count', Math.min(gap, 50));
    form.setValue('fillGaps', false);
  };

  const onSubmit = async (data: BulkGenerateFormData) => {
    setProgress({
      status: 'running',
      total: data.count || 10,
      completed: 0,
      failed: 0,
      errors: [],
    });

    // TODO: Implement actual bulk generation when backend supports it
    // For now, simulate progress
    const total = data.count || 10;
    for (let i = 0; i < total; i++) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      setProgress((prev) => ({
        ...prev,
        completed: i + 1,
        currentNode: `Node ${i + 1}`,
      }));
    }

    setProgress((prev) => ({
      ...prev,
      status: 'completed',
      currentNode: undefined,
    }));
  };

  const handlePause = () => {
    setProgress((prev) => ({
      ...prev,
      status: prev.status === 'running' ? 'paused' : 'running',
    }));
  };

  const handleCancel = () => {
    setProgress({
      status: 'idle',
      total: 0,
      completed: 0,
      failed: 0,
      errors: [],
    });
  };

  const isRunning = progress.status === 'running' || progress.status === 'paused';

  return (
    <div className="space-y-6">
      <DistributionGapChart onSelectGap={handleGapSelect} />

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Boxes className="size-5" />
            Bulk Generate
          </CardTitle>
          <CardDescription>
            Generate multiple nodes at once to fill distribution gaps
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isRunning ? (
            <div className="space-y-6">
              <div className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span>
                    {progress.status === 'paused' ? 'Paused' : 'Generating'}...
                  </span>
                  <span>
                    {progress.completed} / {progress.total}
                  </span>
                </div>
                <Progress value={(progress.completed / progress.total) * 100} />
                {progress.currentNode && (
                  <p className="text-sm text-muted-foreground">
                    Currently generating: {progress.currentNode}
                  </p>
                )}
              </div>

              <div className="flex gap-3">
                {progress.completed > 0 && (
                  <Badge variant="outline" className="gap-1">
                    ✓ {progress.completed} completed
                  </Badge>
                )}
                {progress.failed > 0 && (
                  <Badge variant="destructive" className="gap-1">
                    ✗ {progress.failed} failed
                  </Badge>
                )}
              </div>

              {progress.errors.length > 0 && (
                <div className="rounded-lg border border-red-500/50 bg-red-500/10 p-3 space-y-1">
                  <p className="text-sm font-medium text-red-500">Errors:</p>
                  <ul className="list-disc list-inside space-y-0.5">
                    {progress.errors.map((error, i) => (
                      <li key={i} className="text-sm text-red-400">{error}</li>
                    ))}
                  </ul>
                </div>
              )}

              <div className="flex gap-3">
                <Button variant="outline" onClick={handlePause}>
                  {progress.status === 'paused' ? (
                    <>
                      <Play className="mr-2 size-4" />
                      Resume
                    </>
                  ) : (
                    <>
                      <Pause className="mr-2 size-4" />
                      Pause
                    </>
                  )}
                </Button>
                <Button variant="destructive" onClick={handleCancel}>
                  Cancel
                </Button>
              </div>
            </div>
          ) : progress.status === 'completed' ? (
            <div className="space-y-4">
              <div className="rounded-lg border border-green-500/50 bg-green-500/10 p-4">
                <p className="font-medium text-green-500">Generation Complete!</p>
                <p className="text-sm text-muted-foreground">
                  Successfully generated {progress.completed} nodes
                  {progress.failed > 0 && ` (${progress.failed} failed)`}
                </p>
              </div>
              <Button variant="outline" onClick={handleCancel}>
                Generate More
              </Button>
            </div>
          ) : (
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                <FormField
                  control={form.control}
                  name="fillGaps"
                  render={({ field }) => (
                    <FormItem className="flex items-center justify-between rounded-lg border p-4">
                      <div className="space-y-0.5">
                        <FormLabel className="text-base">Auto-fill Gaps</FormLabel>
                        <FormDescription>
                          Automatically generate nodes to meet distribution targets
                        </FormDescription>
                      </div>
                      <FormControl>
                        <Switch checked={field.value} onCheckedChange={field.onChange} />
                      </FormControl>
                    </FormItem>
                  )}
                />

                {!fillGaps && (
                  <div className="grid gap-6 sm:grid-cols-3">
                    <FormField
                      control={form.control}
                      name="biome"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Biome</FormLabel>
                          <Select onValueChange={field.onChange} value={field.value}>
                            <FormControl>
                              <SelectTrigger>
                                <SelectValue placeholder="Any biome" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              <SelectItem value="">Any biome</SelectItem>
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

                    <FormField
                      control={form.control}
                      name="nodeType"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Node Type</FormLabel>
                          <Select onValueChange={field.onChange} value={field.value}>
                            <FormControl>
                              <SelectTrigger>
                                <SelectValue placeholder="Any type" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              <SelectItem value="">Any type</SelectItem>
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
                      name="count"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Count</FormLabel>
                          <FormControl>
                            <Input
                              type="number"
                              min={1}
                              max={50}
                              placeholder="10"
                              {...field}
                              onChange={(e) => field.onChange(e.target.valueAsNumber)}
                            />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>
                )}

                <Button type="submit" className="w-full">
                  <Boxes className="mr-2 size-4" />
                  {fillGaps ? 'Fill All Gaps' : 'Start Bulk Generation'}
                </Button>

                <p className="text-center text-xs text-muted-foreground">
                  Bulk generation is not yet fully implemented. Click the chart above to select a
                  gap to fill.
                </p>
              </form>
            </Form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
