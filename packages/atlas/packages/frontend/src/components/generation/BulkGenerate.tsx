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
import { DistributionGapChart } from './DistributionGapChart';
import { BulkGeneratePanel } from '@diggings/authoring-core-frontend';
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

  return (
    <div className="space-y-6">
      <DistributionGapChart onSelectGap={handleGapSelect} />

      <BulkGeneratePanel
        title="Bulk Generate"
        description="Generate multiple nodes at once to fill distribution gaps"
        progress={progress}
        onCancel={cancel}
        onReset={reset}
      >
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
                        <Input type="number" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            )}

            <Button type="submit" className="w-full">
              Generate
            </Button>
          </form>
        </Form>
      </BulkGeneratePanel>
    </div>
  );
}
