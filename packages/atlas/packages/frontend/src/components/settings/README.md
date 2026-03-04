# Settings Components

This directory contains React components for managing LLM providers and generation settings.

## Components

### ProviderList

Displays a table of LLM providers with actions to edit, test, delete, and set active.

**Props:**
- `onEdit: (providerId: number) => void` - Callback when edit button is clicked

**Features:**
- Displays provider name, type, model, status, and API key status
- Test connection button with loading state and result toast
- Set active button (only shown for inactive providers with API keys)
- Delete button with confirmation dialog
- Shows loading state while fetching providers
- Shows empty state when no providers exist

**Usage:**
```tsx
import { ProviderList } from '@/components/settings';

function ProvidersPage() {
  const [editingId, setEditingId] = useState<number | undefined>();

  return <ProviderList onEdit={setEditingId} />;
}
```

### ProviderFormDialog

A dialog form for creating or editing LLM providers.

**Props:**
- `open: boolean` - Controls dialog visibility
- `onOpenChange: (open: boolean) => void` - Callback when dialog open state changes
- `providerId?: number` - Optional provider ID for editing (omit for creating)

**Features:**
- Create or edit mode based on `providerId` prop
- Validates with Zod schema (LLMProviderConfigSchema)
- Fields: name, type, baseUrl, apiKey, model, temperature, maxRetries, isActive
- Temperature slider (0-100, displays as 0.0-1.0)
- Max retries slider (0-10)
- When editing, API key field is optional (keeps existing if empty)
- Shows loading state during submission
- Success/error toasts
- Auto-resets form when closed

**Usage:**
```tsx
import { ProviderFormDialog } from '@/components/settings';

function ProvidersPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | undefined>();

  return (
    <>
      <Button onClick={() => setDialogOpen(true)}>Add Provider</Button>
      <ProviderFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        providerId={editingId}
      />
    </>
  );
}
```

### GenerationSettingsForm

A form for updating generation settings.

**Props:**
- `settings: GenerationSettings` - Current generation settings object

**Features:**
- Validates with Zod schema (GenerationSettingsUpdateSchema)
- Fields: batchSize, criticThreshold, enableCriticStage, defaultTemperature, maxRetries
- All numeric fields use sliders with real-time value display
- Save button only enabled when form is dirty (has changes)
- Shows loading state during submission
- Success/error toasts

**Usage:**
```tsx
import { GenerationSettingsForm } from '@/components/settings';
import { useGenerationSettings } from '@/hooks/useAdvancedConfig';

function SettingsPage() {
  const { data: settings } = useGenerationSettings();

  if (!settings) {
    return <div>Loading...</div>;
  }

  return <GenerationSettingsForm settings={settings} />;
}
```

## Complete Example

Here's a complete example of a settings page using all three components:

```tsx
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  ProviderList,
  ProviderFormDialog,
  GenerationSettingsForm,
} from '@/components/settings';
import { useGenerationSettings } from '@/hooks/useAdvancedConfig';

export function SettingsPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | undefined>();
  const { data: settings } = useGenerationSettings();

  const handleEdit = (providerId: number) => {
    setEditingId(providerId);
    setDialogOpen(true);
  };

  const handleDialogClose = (open: boolean) => {
    if (!open) {
      setEditingId(undefined);
    }
    setDialogOpen(open);
  };

  return (
    <div className="container py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Settings</h1>
        <p className="text-muted-foreground">
          Manage LLM providers and generation settings.
        </p>
      </div>

      <Tabs defaultValue="providers" className="space-y-6">
        <TabsList>
          <TabsTrigger value="providers">LLM Providers</TabsTrigger>
          <TabsTrigger value="generation">Generation Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="providers" className="space-y-4">
          <div className="flex justify-end">
            <Button onClick={() => setDialogOpen(true)}>Add Provider</Button>
          </div>
          <ProviderList onEdit={handleEdit} />
          <ProviderFormDialog
            open={dialogOpen}
            onOpenChange={handleDialogClose}
            providerId={editingId}
          />
        </TabsContent>

        <TabsContent value="generation">
          {settings ? (
            <GenerationSettingsForm settings={settings} />
          ) : (
            <div>Loading settings...</div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

## Dependencies

These components use:
- **UI Components**: `@/components/ui/*` (shadcn/ui)
- **Icons**: `lucide-react` (Check, X, Trash2, TestTube, Edit, Save, Loader2)
- **Toast**: `sonner` for notifications
- **Forms**: `react-hook-form` with `@hookform/resolvers/zod`
- **Hooks**: `@/hooks/useLLMProviders`, `@/hooks/useAdvancedConfig`
- **Types**: `@node-gen-web/shared`

## Error Handling

All components include proper error handling:
- Network errors show toast notifications
- Form validation errors display inline
- Loading states prevent multiple submissions
- Confirmation dialogs for destructive actions
