import { useState } from 'react';
import { Edit } from 'lucide-react';
import { toast } from 'sonner';
import { errorToast } from '@/lib/toast-utils';
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
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { useStyleGuides, useUpdateStyleGuide } from '@/hooks/useAdvancedConfig';
import type { StyleGuideRecord, StyleGuideUpdate } from '@node-gen-web/shared';

const BIOME_DISPLAY_NAMES: Record<string, string> = {
  township: 'Township',
  the_diggings: 'The Diggings',
  the_bush: 'The Bush',
  the_mines: 'The Mines',
  the_waste: 'The Waste',
  the_scar: 'The Scar',
  sacred_site: 'Sacred Site',
  the_river: 'The River',
};

interface FormData {
  atmosphere: string;
  sensoryDetails: string;
  dangers: string;
  voiceNotes: string;
  antipatterns: string;
}

export function StyleGuideEditor() {
  const { data: styleGuides, isLoading } = useStyleGuides();
  const updateMutation = useUpdateStyleGuide();
  const [showDialog, setShowDialog] = useState(false);
  const [editingGuide, setEditingGuide] = useState<StyleGuideRecord | undefined>(undefined);

  const {
    register,
    handleSubmit,
    reset,
  } = useForm<FormData>({
    defaultValues: {
      atmosphere: '',
      sensoryDetails: '',
      dangers: '',
      voiceNotes: '',
      antipatterns: '',
    },
  });

  const handleEdit = (guide: StyleGuideRecord) => {
    reset({
      atmosphere: guide.atmosphere || '',
      sensoryDetails: guide.sensoryDetails?.join(', ') || '',
      dangers: guide.dangers?.join(', ') || '',
      voiceNotes: guide.voiceNotes || '',
      antipatterns: guide.antipatterns?.join(', ') || '',
    });
    setEditingGuide(guide);
    setShowDialog(true);
  };

  const parseCommaSeparated = (value: string): string[] => {
    return value
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
  };

  const onSubmit = async (data: FormData) => {
    if (!editingGuide) return;

    const updates: StyleGuideUpdate = {
      atmosphere: data.atmosphere || undefined,
      sensoryDetails: parseCommaSeparated(data.sensoryDetails),
      dangers: parseCommaSeparated(data.dangers),
      voiceNotes: data.voiceNotes || undefined,
      antipatterns: parseCommaSeparated(data.antipatterns),
    };

    try {
      await updateMutation.mutateAsync({
        biome: editingGuide.biome,
        updates,
      });
      toast.success('Style guide updated successfully');
      setShowDialog(false);
      reset();
    } catch (error) {
      errorToast('Failed to update style guide');
    }
  };

  const renderArrayBadges = (items: string[] | undefined | null, max = 3) => {
    if (!items || items.length === 0) {
      return <span className="text-muted-foreground">-</span>;
    }
    const displayed = items.slice(0, max);
    const remaining = items.length - max;
    return (
      <div className="flex flex-wrap gap-1">
        {displayed.map((item, i) => (
          <Badge key={i} variant="outline" className="text-xs">
            {item}
          </Badge>
        ))}
        {remaining > 0 && (
          <Badge variant="secondary" className="text-xs">
            +{remaining} more
          </Badge>
        )}
      </div>
    );
  };

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle>Style Guides</CardTitle>
          <CardDescription>
            Per-biome style guidelines for AI content generation. Define atmosphere, sensory details, dangers, and writing notes.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 8 }).map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : styleGuides && styleGuides.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Biome</TableHead>
                  <TableHead>Atmosphere</TableHead>
                  <TableHead>Sensory Details</TableHead>
                  <TableHead>Dangers</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {styleGuides.map((guide) => (
                  <TableRow key={guide.id}>
                    <TableCell className="font-medium">
                      {BIOME_DISPLAY_NAMES[guide.biome] || guide.biome}
                    </TableCell>
                    <TableCell className="max-w-xs truncate text-sm text-muted-foreground">
                      {guide.atmosphere || '-'}
                    </TableCell>
                    <TableCell>{renderArrayBadges(guide.sensoryDetails)}</TableCell>
                    <TableCell>{renderArrayBadges(guide.dangers)}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" onClick={() => handleEdit(guide)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              No style guides found. Style guides are created per biome.
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              Edit Style Guide: {editingGuide ? BIOME_DISPLAY_NAMES[editingGuide.biome] : ''}
            </DialogTitle>
            <DialogDescription>
              Configure the style guidelines for this biome. Arrays use comma-separated values.
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="atmosphere">Atmosphere</Label>
              <Textarea
                id="atmosphere"
                {...register('atmosphere')}
                placeholder="Describe the overall atmosphere and mood of this biome..."
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="sensoryDetails">Sensory Details</Label>
              <Textarea
                id="sensoryDetails"
                {...register('sensoryDetails')}
                placeholder="e.g., acrid smoke, distant pickaxe strikes, flickering lantern light"
                rows={2}
              />
              <p className="text-xs text-muted-foreground">
                Comma-separated list of sensory details typical of this biome
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="dangers">Dangers</Label>
              <Textarea
                id="dangers"
                {...register('dangers')}
                placeholder="e.g., cave-ins, claim jumpers, poisonous snakes"
                rows={2}
              />
              <p className="text-xs text-muted-foreground">
                Comma-separated list of dangers and threats in this biome
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="voiceNotes">Voice Notes</Label>
              <Textarea
                id="voiceNotes"
                {...register('voiceNotes')}
                placeholder="Notes on narrative voice, tone, and writing style for this biome..."
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="antipatterns">Antipatterns</Label>
              <Textarea
                id="antipatterns"
                {...register('antipatterns')}
                placeholder="e.g., modern slang, anachronistic technology, overly flowery prose"
                rows={2}
              />
              <p className="text-xs text-muted-foreground">
                Comma-separated list of things to avoid in generated content
              </p>
            </div>

            <div className="flex justify-end gap-2 pt-4">
              <Button type="button" variant="outline" onClick={() => setShowDialog(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={updateMutation.isPending}>
                {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
