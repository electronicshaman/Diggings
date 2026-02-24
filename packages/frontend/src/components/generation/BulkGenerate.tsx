import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Boxes } from 'lucide-react';
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
import { useBulkGeneration } from '@/hooks/useGeneration';
import { NodeTypeDisplayNames, BiomeDisplayNames, type Biome, type NodeType } from '@node-gen-web/shared';

const bulkGenerateSchema = z.object({
  biome: z.string().optional(),
  nodeType: z.string().optional(),
  count: z.number().int().min(1).max(50).optional(),
  fillGaps: z.boolean().default(true),
});

type BulkGenerateFormData = z.infer<typeof bulkGenerateSchema>;

export function BulkGenerate() {
  const { progress, start, cancel, reset } = useBulkGeneration();

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
    await start({
      biome: data.fillGaps ? undefined : (data.biome as any),
      nodeType: data.fillGaps ? undefined : (data.nodeType as any),
      count: data.fillGaps ? undefined : data.count,
      fillGaps: data.fillGaps,
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
                    {progress.completed + progress.failed} / {progress.total}
                  </span>
                </div>
                <Progress
                  value={
                    progress.total > 0
                      ? ((progress.completed + progress.failed) / progress.total) * 100
                      : 0
                  }
                />
                {progress.currentNode && (
                  <p className="text-sm text-muted-foreground">
                    Currently generating: {progress.currentNode.slice(0, 8)}...
                  </p>
                )}
              </div>

              <div className="flex gap-3">
                {progress.completed > 0 && (
                  <Badge variant="outline" className="gap-1">
                    {progress.completed} completed
                  </Badge>
                )}
                {progress.failed > 0 && (
                  <Badge variant="destructive" className="gap-1">
                    {progress.failed} failed
                  </Badge>
                )}
              </div>

              <div className="flex gap-3">
                <Button variant="destructive" onClick={cancel}>
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
              {progress.errors.length > 0 && (
                <div className="max-h-32 overflow-y-auto rounded border p-2 text-xs text-muted-foreground">
                  {progress.errors.map((err, i) => (
                    <p key={i}>{err}</p>
                  ))}
                </div>
              )}
              <Button variant="outline" onClick={reset}>
                Generate More
              </Button>
            </div>
          ) : progress.status === 'error' ? (
            <div className="space-y-4">
              <div className="rounded-lg border border-red-500/50 bg-red-500/10 p-4">
                <p className="font-medium text-red-500">Generation Failed</p>
                {progress.errors.map((err, i) => (
                  <p key={i} className="text-sm text-muted-foreground">
                    {err}
                  </p>
                ))}
              </div>
              <Button variant="outline" onClick={reset}>
                Try Again
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
              </form>
            </Form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
