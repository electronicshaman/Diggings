import { useState } from 'react';
import { Check, X, Trash2, TestTube, Edit, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  useLLMProviders,
  useUpdateProvider,
  useDeleteProvider,
  useTestProvider,
} from '@/hooks/useLLMProviders';
import type { LLMProviderTestResult } from '@node-gen-web/shared';

interface ProviderListProps {
  onEdit: (providerId: number) => void;
}

export function ProviderList({ onEdit }: ProviderListProps) {
  const { data: providers, isLoading } = useLLMProviders();
  const updateProvider = useUpdateProvider();
  const deleteProvider = useDeleteProvider();
  const testProvider = useTestProvider();
  const [testingId, setTestingId] = useState<number | null>(null);

  const handleSetActive = async (id: number) => {
    try {
      await updateProvider.mutateAsync({ id, updates: { isActive: true } });
      toast.success('Provider activated successfully');
    } catch (error) {
      toast.error(`Failed to activate provider: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Are you sure you want to delete provider "${name}"?`)) {
      return;
    }

    try {
      await deleteProvider.mutateAsync(id);
      toast.success('Provider deleted successfully');
    } catch (error) {
      toast.error(`Failed to delete provider: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const handleTest = async (id: number) => {
    setTestingId(id);
    try {
      const result: LLMProviderTestResult = await testProvider.mutateAsync({ providerId: id });

      if (result.success) {
        toast.success(
          <div>
            <div className="font-semibold">Connection successful</div>
            <div className="text-sm text-muted-foreground">
              {result.message}
              {result.latency && ` (${result.latency}ms)`}
            </div>
          </div>
        );
      } else {
        toast.error(
          <div>
            <div className="font-semibold">Connection failed</div>
            <div className="text-sm">{result.error || result.message}</div>
          </div>
        );
      }
    } catch (error) {
      toast.error(
        <div>
          <div className="font-semibold">Connection test failed</div>
          <div className="text-sm">{error instanceof Error ? error.message : 'Unknown error'}</div>
        </div>
      );
    } finally {
      setTestingId(null);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!providers || providers.length === 0) {
    return (
      <div className="rounded-lg border border-dashed p-8 text-center">
        <p className="text-muted-foreground">No LLM providers configured yet.</p>
        <p className="text-sm text-muted-foreground mt-2">
          Click the "Add Provider" button to create your first provider.
        </p>
      </div>
    );
  }

  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Model</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>API Key</TableHead>
            <TableHead className="text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {providers.map((provider) => (
            <TableRow key={provider.id}>
              <TableCell className="font-medium">{provider.name}</TableCell>
              <TableCell>
                <Badge variant="outline" className="capitalize">
                  {provider.type}
                </Badge>
              </TableCell>
              <TableCell className="text-sm text-muted-foreground">
                {provider.model}
              </TableCell>
              <TableCell>
                {provider.isActive ? (
                  <Badge variant="default" className="gap-1">
                    <Check className="h-3 w-3" />
                    Active
                  </Badge>
                ) : (
                  <Badge variant="secondary" className="gap-1">
                    <X className="h-3 w-3" />
                    Inactive
                  </Badge>
                )}
              </TableCell>
              <TableCell>
                {provider.type === 'ollama' ? (
                  <Badge variant="secondary" className="gap-1">
                    N/A
                  </Badge>
                ) : provider.hasApiKey ? (
                  <Badge variant="outline" className="gap-1">
                    <Check className="h-3 w-3" />
                    Configured
                  </Badge>
                ) : (
                  <Badge variant="destructive" className="gap-1">
                    <X className="h-3 w-3" />
                    Missing
                  </Badge>
                )}
              </TableCell>
              <TableCell className="text-right">
                <div className="flex justify-end gap-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onEdit(provider.id)}
                    title="Edit provider"
                  >
                    <Edit className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleTest(provider.id)}
                    disabled={(!provider.hasApiKey && provider.type !== 'ollama') || testingId === provider.id}
                    title="Test connection"
                  >
                    {testingId === provider.id ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <TestTube className="h-4 w-4" />
                    )}
                  </Button>
                  {!provider.isActive && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleSetActive(provider.id)}
                      disabled={!provider.hasApiKey && provider.type !== 'ollama'}
                      title="Set as active provider"
                    >
                      <Check className="h-4 w-4" />
                    </Button>
                  )}
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleDelete(provider.id, provider.name)}
                    title="Delete provider"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
