import { useState } from 'react';
import { Edit } from 'lucide-react';
import { toast } from 'sonner';
import { useForm } from 'react-hook-form';
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
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { useActTones, useUpdateActTone } from '@/hooks/useAdvancedConfig';
import type { ActToneRecord, ActToneUpdate } from '@atlas/shared';

interface ActToneFormData {
  toneName: string;
  description: string;
  sensoryPaletteJson: string;
}

export function ActToneEditor() {
  const { data: actTones, isLoading } = useActTones();
  const updateMutation = useUpdateActTone();
  const [showDialog, setShowDialog] = useState(false);
  const [editingTone, setEditingTone] = useState<ActToneRecord | undefined>(undefined);
  const [jsonError, setJsonError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ActToneFormData>({
    defaultValues: {
      toneName: '',
      description: '',
      sensoryPaletteJson: '{}',
    },
  });

  const handleEdit = (tone: ActToneRecord) => {
    reset({
      toneName: tone.toneName,
      description: tone.description || '',
      sensoryPaletteJson: JSON.stringify(tone.sensoryPalette || {}, null, 2),
    });
    setJsonError(null);
    setEditingTone(tone);
    setShowDialog(true);
  };

  const onSubmit = async (data: ActToneFormData) => {
    if (!editingTone) return;

    let parsedPalette: unknown;
    try {
      parsedPalette = JSON.parse(data.sensoryPaletteJson);
      setJsonError(null);
    } catch {
      setJsonError('Invalid JSON format');
      return;
    }

    const updates: ActToneUpdate = {
      toneName: data.toneName,
      description: data.description || undefined,
      sensoryPalette: parsedPalette,
    };

    try {
      await updateMutation.mutateAsync({
        act: editingTone.act,
        updates,
      });
      toast.success('Act tone updated successfully');
      setShowDialog(false);
      reset();
    } catch {
      toast.error('Failed to update act tone');
    }
  };

  const sortedTones = actTones ? [...actTones].sort((a, b) => a.act - b.act) : [];

  const getActLabel = (act: number) => {
    const labels: Record<number, string> = {
      1: 'Act I - Arrival',
      2: 'Act II - Establishment',
      3: 'Act III - Crisis',
      4: 'Act IV - Resolution',
    };
    return labels[act] || `Act ${act}`;
  };

  return (
    <>
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Act Tones</CardTitle>
            <CardDescription>
              Configure narrative tone and sensory palette for each act. These guide AI generation
              to maintain consistent atmosphere throughout the story progression.
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : sortedTones.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-32">Act</TableHead>
                  <TableHead>Tone Name</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Sensory Palette</TableHead>
                  <TableHead className="text-right w-24">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedTones.map((tone) => (
                  <TableRow key={tone.id}>
                    <TableCell>
                      <Badge variant="outline">{getActLabel(tone.act)}</Badge>
                    </TableCell>
                    <TableCell className="font-medium">{tone.toneName}</TableCell>
                    <TableCell className="text-sm text-muted-foreground max-w-md truncate">
                      {tone.description || '-'}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {tone.sensoryPalette ? (
                        <span className="font-mono text-xs">
                          {Object.keys(tone.sensoryPalette).length} keys
                        </span>
                      ) : (
                        '-'
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" onClick={() => handleEdit(tone)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              No act tones configured. Run database seed to initialize default values.
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>
              Edit {editingTone ? getActLabel(editingTone.act) : 'Act'} Tone
            </DialogTitle>
            <DialogDescription>
              Configure the narrative tone and sensory guidance for this act.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="toneName">Tone Name</Label>
              <Input
                id="toneName"
                {...register('toneName', { required: 'Tone name is required' })}
                placeholder="e.g., Hopeful Uncertainty"
              />
              {errors.toneName && (
                <p className="text-sm text-red-600">{errors.toneName.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                {...register('description')}
                placeholder="Describe the overall tone and mood for this act..."
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="sensoryPaletteJson">
                Sensory Palette (JSON)
              </Label>
              <Textarea
                id="sensoryPaletteJson"
                {...register('sensoryPaletteJson')}
                placeholder='{"colors": ["dusty gold", "sun-bleached"], "sounds": ["distant pickaxe"], ...}'
                rows={8}
                className="font-mono text-sm"
              />
              {jsonError && <p className="text-sm text-red-600">{jsonError}</p>}
              <p className="text-xs text-muted-foreground">
                Flexible JSON structure for sensory details. Common keys: colors, sounds, smells,
                textures, temperatures, lighting.
              </p>
            </div>

            <div className="flex justify-end gap-2 pt-4">
              <Button type="button" variant="outline" onClick={() => setShowDialog(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={updateMutation.isPending}>
                Update
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
