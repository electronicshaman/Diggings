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
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import {
  useBeatRoles,
  useCreateBeatRole,
  useUpdateBeatRole,
  useDeleteBeatRole,
} from '@/hooks/useAdvancedConfig';
import { BeatRoleCreateSchema, type BeatRoleCreate, type BeatRoleRecord } from '@atlas/shared';

interface BeatRoleFormData extends BeatRoleCreate {}

export function BeatRoleEditor() {
  const { data: beatRoles, isLoading } = useBeatRoles();
  const createMutation = useCreateBeatRole();
  const updateMutation = useUpdateBeatRole();
  const deleteMutation = useDeleteBeatRole();
  const [showDialog, setShowDialog] = useState(false);
  const [editingRole, setEditingRole] = useState<BeatRoleRecord | undefined>(undefined);

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    reset,
    formState: { errors },
  } = useForm<BeatRoleFormData>({
    resolver: zodResolver(BeatRoleCreateSchema),
    defaultValues: {
      key: '',
      displayName: '',
      description: '',
      isCore: false,
      sortOrder: 0,
    },
  });

  const isCore = watch('isCore');

  const handleAdd = () => {
    reset({
      key: '',
      displayName: '',
      description: '',
      isCore: false,
      sortOrder: beatRoles ? beatRoles.length : 0,
    });
    setEditingRole(undefined);
    setShowDialog(true);
  };

  const handleEdit = (role: BeatRoleRecord) => {
    reset({
      key: role.key,
      displayName: role.displayName,
      description: role.description || '',
      isCore: role.isCore,
      sortOrder: role.sortOrder,
    });
    setEditingRole(role);
    setShowDialog(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this beat role?')) return;

    try {
      await deleteMutation.mutateAsync(id);
      toast.success('Beat role deleted successfully');
    } catch (error) {
      toast.error('Failed to delete beat role');
    }
  };

  const handleMoveSortOrder = async (role: BeatRoleRecord, direction: 'up' | 'down') => {
    if (!beatRoles) return;

    const currentIndex = beatRoles.findIndex((r) => r.id === role.id);
    const targetIndex = direction === 'up' ? currentIndex - 1 : currentIndex + 1;

    if (targetIndex < 0 || targetIndex >= beatRoles.length) return;

    const targetRole = beatRoles[targetIndex];

    try {
      // Swap sort orders
      await Promise.all([
        updateMutation.mutateAsync({
          id: role.id,
          updates: { sortOrder: targetRole.sortOrder },
        }),
        updateMutation.mutateAsync({
          id: targetRole.id,
          updates: { sortOrder: role.sortOrder },
        }),
      ]);
      toast.success('Sort order updated');
    } catch (error) {
      toast.error('Failed to update sort order');
    }
  };

  const onSubmit = async (data: BeatRoleFormData) => {
    try {
      if (editingRole) {
        await updateMutation.mutateAsync({
          id: editingRole.id,
          updates: data,
        });
        toast.success('Beat role updated successfully');
      } else {
        await createMutation.mutateAsync(data);
        toast.success('Beat role created successfully');
      }
      setShowDialog(false);
      reset();
    } catch (error) {
      toast.error(`Failed to ${editingRole ? 'update' : 'create'} beat role`);
    }
  };

  const sortedRoles = beatRoles ? [...beatRoles].sort((a, b) => a.sortOrder - b.sortOrder) : [];

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Beat Roles</CardTitle>
            <CardDescription>
              Manage the available beat roles for story beat composition. Core roles are system defaults.
            </CardDescription>
          </div>
          <Button onClick={handleAdd}>
            <Plus className="h-4 w-4 mr-2" />
            Add Role
          </Button>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : sortedRoles.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Key</TableHead>
                  <TableHead>Display Name</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead className="text-center">Sort Order</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedRoles.map((role, index) => (
                  <TableRow key={role.id}>
                    <TableCell className="font-mono text-sm">{role.key}</TableCell>
                    <TableCell className="font-medium">{role.displayName}</TableCell>
                    <TableCell>
                      {role.isCore ? (
                        <Badge variant="default">Core</Badge>
                      ) : (
                        <Badge variant="secondary">Extended</Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground max-w-md truncate">
                      {role.description || '-'}
                    </TableCell>
                    <TableCell className="text-center">
                      <div className="flex items-center justify-center gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleMoveSortOrder(role, 'up')}
                          disabled={index === 0}
                        >
                          <ArrowUp className="h-3 w-3" />
                        </Button>
                        <span className="text-xs text-muted-foreground w-6">{role.sortOrder}</span>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleMoveSortOrder(role, 'down')}
                          disabled={index === sortedRoles.length - 1}
                        >
                          <ArrowDown className="h-3 w-3" />
                        </Button>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button variant="ghost" size="sm" onClick={() => handleEdit(role)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleDelete(role.id)}
                          disabled={role.isCore}
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
              No beat roles configured. Add one to get started.
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingRole ? 'Edit Beat Role' : 'Add Beat Role'}</DialogTitle>
            <DialogDescription>
              Define a beat role that can be used in story beat sequences.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="key">Key</Label>
              <Input
                id="key"
                {...register('key')}
                placeholder="e.g., tension"
                disabled={!!editingRole}
              />
              {errors.key && <p className="text-sm text-red-600">{errors.key.message}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="displayName">Display Name</Label>
              <Input
                id="displayName"
                {...register('displayName')}
                placeholder="e.g., Tension"
              />
              {errors.displayName && (
                <p className="text-sm text-red-600">{errors.displayName.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description (optional)</Label>
              <Textarea
                id="description"
                {...register('description')}
                placeholder="Describe the purpose of this beat role..."
                rows={3}
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

            <div className="flex items-center space-x-2">
              <Checkbox
                id="isCore"
                checked={isCore}
                onCheckedChange={(checked) => setValue('isCore', !!checked)}
              />
              <Label htmlFor="isCore" className="text-sm font-normal cursor-pointer">
                Core role (system default)
              </Label>
            </div>

            <div className="flex justify-end gap-2 pt-4">
              <Button type="button" variant="outline" onClick={() => setShowDialog(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createMutation.isPending || updateMutation.isPending}>
                {editingRole ? 'Update' : 'Create'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
