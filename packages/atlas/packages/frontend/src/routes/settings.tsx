import { useState } from 'react';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useGenerationSettings } from '@/hooks/useAdvancedConfig';
import { ProviderList } from '@/components/settings/ProviderList';
import { ProviderFormDialog } from '@/components/settings/ProviderFormDialog';
import { GenerationSettingsForm } from '@/components/settings/GenerationSettingsForm';

export default function SettingsPage() {
  const { data: settings, isLoading: settingsLoading } = useGenerationSettings();
  const [showProviderForm, setShowProviderForm] = useState(false);
  const [editingProviderId, setEditingProviderId] = useState<number | undefined>(undefined);

  const handleEdit = (providerId: number) => {
    setEditingProviderId(providerId);
    setShowProviderForm(true);
  };

  const handleCloseForm = () => {
    setShowProviderForm(false);
    setEditingProviderId(undefined);
  };

  return (
    <div className="container mx-auto py-8 px-4 space-y-8">
      <div>
        <h1 className="text-3xl font-bold">Settings</h1>
        <p className="text-muted-foreground">Manage LLM providers and generation settings</p>
      </div>

      {/* LLM Providers Section */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>LLM Providers</CardTitle>
            <CardDescription>
              Configure AI providers for content generation. Set API keys and model preferences.
            </CardDescription>
          </div>
          <Button onClick={() => setShowProviderForm(true)}>
            <Plus className="h-4 w-4 mr-2" />
            Add Provider
          </Button>
        </CardHeader>
        <CardContent>
          <ProviderList onEdit={handleEdit} />
        </CardContent>
      </Card>

      {/* Generation Settings Section */}
      <Card>
        <CardHeader>
          <CardTitle>Generation Settings</CardTitle>
          <CardDescription>
            Configure default settings for AI content generation, including batch size, quality thresholds, and retry
            behavior.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {settingsLoading ? (
            <div className="text-center py-8 text-muted-foreground">Loading settings...</div>
          ) : settings ? (
            <GenerationSettingsForm settings={settings} />
          ) : (
            <div className="text-center py-8 text-muted-foreground">Failed to load settings.</div>
          )}
        </CardContent>
      </Card>

      {/* Provider Form Dialog */}
      <ProviderFormDialog open={showProviderForm} onOpenChange={handleCloseForm} providerId={editingProviderId} />
    </div>
  );
}
