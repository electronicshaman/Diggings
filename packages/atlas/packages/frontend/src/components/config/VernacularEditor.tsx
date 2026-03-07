import { useState } from 'react';
import { Plus, Edit, Trash2, ArrowUp, ArrowDown } from 'lucide-react';
import { toast } from 'sonner';
import { useForm } from 'react-hook-form';
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Skeleton } from '@/components/ui/skeleton';
import {
  useVernacular,
  useCreateVernacular,
  useUpdateVernacular,
  useDeleteVernacular,
} from '@/hooks/useAdvancedConfig';
import { VernacularCreateSchema, type VernacularCreate, type VernacularRecord } from '@atlas/shared';

interface VernacularFormData extends VernacularCreate {}

export function VernacularEditor() {
  const { data: vernacularTerms, isLoading } = useVernacular();
  const createMutation = useCreateVernacular();
  const updateMutation = useUpdateVernacular();
  const deleteMutation = useDeleteVernacular();
  const [showDialog, setShowDialog] = useState(false);
  const [editingTerm, setEditingTerm] = useState<VernacularRecord | undefined>(undefined);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<VernacularFormData>({
    resolver: zodResolver(VernacularCreateSchema),
    defaultValues: {
      term: '',
      definition: '',
      era: '',
      usageNotes: '',
      sortOrder: 0,
    },
  });

  const handleAdd = () => {
    reset({
      term: '',
      definition: '',
      era: '',
      usageNotes: '',
      sortOrder: vernacularTerms ? vernacularTerms.length : 0,
    });
    setEditingTerm(undefined);
    setShowDialog(true);
  };

  const handleEdit = (term: VernacularRecord) => {
    reset({
      term: term.term,
      definition: term.definition,
      era: term.era || '',
      usageNotes: term.usageNotes || '',
      sortOrder: term.sortOrder,
    });
    setEditingTerm(term);
    setShowDialog(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this vernacular term?')) return;

    try {
      await deleteMutation.mutateAsync(id);
      toast.success('Vernacular term deleted successfully');
    } catch (error) {
      toast.error('Failed to delete vernacular term');
    }
  };

  const handleMoveSortOrder = async (term: VernacularRecord, direction: 'up' | 'down') => {
    if (!vernacularTerms) return;

    const currentIndex = vernacularTerms.findIndex((t) => t.id === term.id);
    const targetIndex = direction === 'up' ? currentIndex - 1 : currentIndex + 1;

    if (targetIndex < 0 || targetIndex >= vernacularTerms.length) return;

    const targetTerm = vernacularTerms[targetIndex];

    try {
      await Promise.all([
        updateMutation.mutateAsync({
          id: term.id,
          updates: { sortOrder: targetTerm.sortOrder },
        }),
        updateMutation.mutateAsync({
          id: targetTerm.id,
          updates: { sortOrder: term.sortOrder },
        }),
      ]);
      toast.success('Sort order updated');
    } catch (error) {
      toast.error('Failed to update sort order');
    }
  };

  const onSubmit = async (data: VernacularFormData) => {
    try {
      if (editingTerm) {
        await updateMutation.mutateAsync({
          id: editingTerm.id,
          updates: {
            term: data.term,
            definition: data.definition,
            era: data.era || null,
            usageNotes: data.usageNotes || null,
            sortOrder: data.sortOrder,
          },
        });
        toast.success('Vernacular term updated successfully');
      } else {
        await createMutation.mutateAsync(data);
        toast.success('Vernacular term created successfully');
      }
      setShowDialog(false);
      reset();
    } catch (error) {
      toast.error(`Failed to ${editingTerm ? 'update' : 'create'} vernacular term`);
    }
  };

  const sortedTerms = vernacularTerms ? [...vernacularTerms].sort((a, b) => a.sortOrder - b.sortOrder) : [];

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Vernacular Terms</CardTitle>
            <CardDescription>
              Manage historical vernacular terms used for period-appropriate language in AI generation.
            </CardDescription>
          </div>
          <Button onClick={handleAdd}>
            <Plus className="h-4 w-4 mr-2" />
            Add Term
          </Button>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : sortedTerms.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Term</TableHead>
                  <TableHead>Definition</TableHead>
                  <TableHead>Era</TableHead>
                  <TableHead>Usage Notes</TableHead>
                  <TableHead className="text-center">Sort Order</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedTerms.map((term, index) => (
                  <TableRow key={term.id}>
                    <TableCell className="font-medium">{term.term}</TableCell>
                    <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                      {term.definition}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {term.era || '-'}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                      {term.usageNotes || '-'}
                    </TableCell>
                    <TableCell className="text-center">
                      <div className="flex items-center justify-center gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleMoveSortOrder(term, 'up')}
                          disabled={index === 0}
                        >
                          <ArrowUp className="h-3 w-3" />
                        </Button>
                        <span className="text-xs text-muted-foreground w-6">{term.sortOrder}</span>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleMoveSortOrder(term, 'down')}
                          disabled={index === sortedTerms.length - 1}
                        >
                          <ArrowDown className="h-3 w-3" />
                        </Button>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button variant="ghost" size="sm" onClick={() => handleEdit(term)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleDelete(term.id)}
                        >
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
              No vernacular terms configured. Add one to get started.
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingTerm ? 'Edit Vernacular Term' : 'Add Vernacular Term'}</DialogTitle>
            <DialogDescription>
              Define a historical term for period-appropriate language generation.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="term">Term</Label>
              <Input
                id="term"
                {...register('term')}
                placeholder="e.g., digger"
              />
              {errors.term && <p className="text-sm text-red-600">{errors.term.message}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="definition">Definition</Label>
              <Textarea
                id="definition"
                {...register('definition')}
                placeholder="The meaning and context of this term..."
                rows={3}
              />
              {errors.definition && (
                <p className="text-sm text-red-600">{errors.definition.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="era">Era (optional)</Label>
              <Input
                id="era"
                {...register('era')}
                placeholder="e.g., 1850s-1860s"
              />
              {errors.era && <p className="text-sm text-red-600">{errors.era.message}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="usageNotes">Usage Notes (optional)</Label>
              <Textarea
                id="usageNotes"
                {...register('usageNotes')}
                placeholder="When and how to use this term appropriately..."
                rows={2}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="sortOrder">Sort Order</Label>
              <Input
                id="sortOrder"
                type="number"
                {...register('sortOrder', { valueAsNumber: true })}
              />
            </div>

            <div className="flex justify-end gap-2 pt-4">
              <Button type="button" variant="outline" onClick={() => setShowDialog(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                {editingTerm ? 'Update' : 'Create'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
