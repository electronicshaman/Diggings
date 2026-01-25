import { useState } from 'react';
import { Plus, Edit, Trash2, Eye, Code } from 'lucide-react';
import { toast } from 'sonner';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Checkbox } from '@/components/ui/checkbox';
import { Textarea } from '@/components/ui/textarea';
import {
  useBeatSequences,
  useCreateBeatSequence,
  useUpdateBeatSequence,
  useDeleteBeatSequence,
} from '@/hooks/useAdvancedConfig';
import {
  BeatSequenceCreateSchema,
  type BeatSequenceCreate,
  type BeatSequenceRecord,
  type BeatTemplate,
} from '@node-gen-web/shared';

const NODE_TYPES = ['combat', 'choice', 'trade', 'rest', 'passage', 'state_check', 'transition'] as const;
const NODE_TYPE_LABELS: Record<string, string> = {
  combat: 'Combat',
  choice: 'Choice',
  trade: 'Trade',
  rest: 'Rest',
  passage: 'Passage',
  state_check: 'State Check',
  transition: 'Transition',
};

interface BeatSequenceFormData extends BeatSequenceCreate {}

export function BeatSequenceEditor() {
  const [selectedNodeType, setSelectedNodeType] = useState<string>('');
  const { data: beatSequences, isLoading } = useBeatSequences(selectedNodeType || undefined);
  const createMutation = useCreateBeatSequence();
  const updateMutation = useUpdateBeatSequence();
  const deleteMutation = useDeleteBeatSequence();
  const [showDialog, setShowDialog] = useState(false);
  const [editingSequence, setEditingSequence] = useState<BeatSequenceRecord | undefined>(undefined);
  const [showJson, setShowJson] = useState(false);

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    reset,
    control,
    formState: { errors },
  } = useForm<BeatSequenceFormData>({
    resolver: zodResolver(BeatSequenceCreateSchema),
    defaultValues: {
      nodeType: 'combat',
      sequenceKey: '',
      beatStructure: [],
      weight: 1,
      actConstraints: null,
      requiredTags: [],
    },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'beatStructure',
  });

  const nodeType = watch('nodeType');
  const beatStructure = watch('beatStructure');

  const handleAdd = () => {
    reset({
      nodeType: (selectedNodeType || 'combat') as BeatSequenceFormData['nodeType'],
      sequenceKey: '',
      beatStructure: [],
      weight: 1,
      actConstraints: null,
      requiredTags: [],
    });
    setEditingSequence(undefined);
    setShowDialog(true);
  };

  const handleEdit = (sequence: BeatSequenceRecord) => {
    reset({
      nodeType: sequence.nodeType,
      sequenceKey: sequence.sequenceKey,
      beatStructure: sequence.beatStructure,
      weight: sequence.weight,
      actConstraints: sequence.actConstraints,
      requiredTags: sequence.requiredTags,
    });
    setEditingSequence(sequence);
    setShowDialog(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this beat sequence?')) return;

    try {
      await deleteMutation.mutateAsync(id);
      toast.success('Beat sequence deleted successfully');
    } catch (error) {
      toast.error('Failed to delete beat sequence');
    }
  };

  const onSubmit = async (data: BeatSequenceFormData) => {
    try {
      if (editingSequence) {
        await updateMutation.mutateAsync({
          id: editingSequence.id,
          updates: data,
        });
        toast.success('Beat sequence updated successfully');
      } else {
        await createMutation.mutateAsync(data);
        toast.success('Beat sequence created successfully');
      }
      setShowDialog(false);
      reset();
    } catch (error) {
      toast.error(`Failed to ${editingSequence ? 'update' : 'create'} beat sequence`);
    }
  };

  const handleAddBeat = () => {
    append({
      role: '',
      intent: '',
      required: true,
    });
  };

  const formatBeatStructure = (beats: BeatTemplate[]) => {
    return beats.map((b) => `${b.role}${b.required ? '*' : ''}`).join(' → ');
  };

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div className="flex-1">
            <CardTitle>Beat Sequences</CardTitle>
            <CardDescription>
              Manage beat sequence templates that define story structure patterns for different node types.
            </CardDescription>
          </div>
          <div className="flex items-center gap-3">
            <Select value={selectedNodeType} onValueChange={setSelectedNodeType}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="All node types" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">All node types</SelectItem>
                {NODE_TYPES.map((type) => (
                  <SelectItem key={type} value={type}>
                    {NODE_TYPE_LABELS[type]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Button onClick={handleAdd}>
              <Plus className="h-4 w-4 mr-2" />
              Add Sequence
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : beatSequences && beatSequences.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Node Type</TableHead>
                  <TableHead>Sequence Key</TableHead>
                  <TableHead>Beat Structure</TableHead>
                  <TableHead className="text-center">Weight</TableHead>
                  <TableHead>Acts</TableHead>
                  <TableHead>Tags</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {beatSequences.map((sequence) => (
                  <TableRow key={sequence.id}>
                    <TableCell>
                      <Badge variant="outline">{NODE_TYPE_LABELS[sequence.nodeType]}</Badge>
                    </TableCell>
                    <TableCell className="font-medium">{sequence.sequenceKey}</TableCell>
                    <TableCell className="font-mono text-xs max-w-md truncate">
                      {formatBeatStructure(sequence.beatStructure)}
                    </TableCell>
                    <TableCell className="text-center">{sequence.weight}</TableCell>
                    <TableCell>
                      {sequence.actConstraints?.acts.length ? (
                        <div className="flex gap-1">
                          {sequence.actConstraints.acts.map((act) => (
                            <Badge key={act} variant="secondary" className="text-xs">
                              Act {act}
                            </Badge>
                          ))}
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-sm">All</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {sequence.requiredTags.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {sequence.requiredTags.slice(0, 2).map((tag) => (
                            <Badge key={tag} variant="secondary" className="text-xs">
                              {tag}
                            </Badge>
                          ))}
                          {sequence.requiredTags.length > 2 && (
                            <Badge variant="secondary" className="text-xs">
                              +{sequence.requiredTags.length - 2}
                            </Badge>
                          )}
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-sm">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button variant="ghost" size="sm" onClick={() => handleEdit(sequence)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => handleDelete(sequence.id)}>
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              No beat sequences found. Add one to get started.
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingSequence ? 'Edit Beat Sequence' : 'Add Beat Sequence'}</DialogTitle>
            <DialogDescription>
              Define a sequence template with beat roles and structure.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="nodeType">Node Type</Label>
                <Select value={nodeType} onValueChange={(value) => setValue('nodeType', value as any)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {NODE_TYPES.map((type) => (
                      <SelectItem key={type} value={type}>
                        {NODE_TYPE_LABELS[type]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.nodeType && <p className="text-sm text-red-600">{errors.nodeType.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="sequenceKey">Sequence Key</Label>
                <Input
                  id="sequenceKey"
                  {...register('sequenceKey')}
                  placeholder="e.g., combat_standard"
                />
                {errors.sequenceKey && (
                  <p className="text-sm text-red-600">{errors.sequenceKey.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="weight">Weight (1-10)</Label>
                <Input
                  id="weight"
                  type="number"
                  min="1"
                  max="10"
                  {...register('weight', { valueAsNumber: true })}
                />
                {errors.weight && <p className="text-sm text-red-600">{errors.weight.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="requiredTags">Required Tags (comma-separated)</Label>
                <Input
                  id="requiredTags"
                  placeholder="tag1, tag2, tag3"
                  onChange={(e) => {
                    const tags = e.target.value.split(',').map((t) => t.trim()).filter(Boolean);
                    setValue('requiredTags', tags);
                  }}
                  defaultValue={watch('requiredTags')?.join(', ') || ''}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Act Constraints (optional)</Label>
              <div className="flex gap-2">
                {[1, 2, 3, 4].map((act) => (
                  <div key={act} className="flex items-center space-x-2">
                    <Checkbox
                      id={`act-${act}`}
                      checked={watch('actConstraints')?.acts?.includes(act) || false}
                      onCheckedChange={(checked) => {
                        const current = watch('actConstraints')?.acts || [];
                        if (checked) {
                          setValue('actConstraints', { acts: [...current, act].sort() });
                        } else {
                          const filtered = current.filter((a) => a !== act);
                          setValue('actConstraints', filtered.length > 0 ? { acts: filtered } : null);
                        }
                      }}
                    />
                    <Label htmlFor={`act-${act}`} className="text-sm font-normal cursor-pointer">
                      Act {act}
                    </Label>
                  </div>
                ))}
              </div>
            </div>

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label>Beat Structure</Label>
                <div className="flex gap-2">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setShowJson(!showJson)}
                  >
                    {showJson ? <Eye className="h-4 w-4 mr-2" /> : <Code className="h-4 w-4 mr-2" />}
                    {showJson ? 'Visual Editor' : 'JSON View'}
                  </Button>
                  <Button type="button" variant="outline" size="sm" onClick={handleAddBeat}>
                    <Plus className="h-4 w-4 mr-2" />
                    Add Beat
                  </Button>
                </div>
              </div>

              {showJson ? (
                <Textarea
                  value={JSON.stringify(beatStructure, null, 2)}
                  onChange={(e) => {
                    try {
                      const parsed = JSON.parse(e.target.value);
                      setValue('beatStructure', parsed);
                    } catch {
                      // Invalid JSON, ignore
                    }
                  }}
                  rows={12}
                  className="font-mono text-xs"
                />
              ) : (
                <div className="space-y-2 border rounded-lg p-4">
                  {fields.length === 0 ? (
                    <p className="text-sm text-muted-foreground text-center py-4">
                      No beats defined. Click "Add Beat" to start.
                    </p>
                  ) : (
                    fields.map((field, index) => (
                      <div key={field.id} className="flex gap-2 items-start p-3 bg-muted/50 rounded">
                        <div className="flex-1 grid grid-cols-3 gap-2">
                          <div>
                            <Label className="text-xs">Role</Label>
                            <Input
                              {...register(`beatStructure.${index}.role`)}
                              placeholder="e.g., setup"
                              className="mt-1"
                            />
                          </div>
                          <div className="col-span-2">
                            <Label className="text-xs">Intent</Label>
                            <Input
                              {...register(`beatStructure.${index}.intent`)}
                              placeholder="Describe the purpose of this beat..."
                              className="mt-1"
                            />
                          </div>
                        </div>
                        <div className="flex items-center gap-2 pt-6">
                          <div className="flex items-center space-x-2">
                            <Checkbox
                              id={`required-${index}`}
                              checked={watch(`beatStructure.${index}.required`)}
                              onCheckedChange={(checked) =>
                                setValue(`beatStructure.${index}.required`, !!checked)
                              }
                            />
                            <Label
                              htmlFor={`required-${index}`}
                              className="text-xs font-normal cursor-pointer"
                            >
                              Required
                            </Label>
                          </div>
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => remove(index)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>

            <div className="flex justify-end gap-2 pt-4">
              <Button type="button" variant="outline" onClick={() => setShowDialog(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                {editingSequence ? 'Update' : 'Create'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
