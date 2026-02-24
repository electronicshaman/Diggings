import { useEffect, useRef } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Loader2, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';
import { useQueryClient } from '@tanstack/react-query';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Slider } from '@/components/ui/slider';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  useCreateProvider,
  useUpdateProvider,
  useLLMProvider,
  useOllamaModels,
} from '@/hooks/useLLMProviders';
import {
  LLMProviderConfigSchema,
  type LLMProviderConfig,
  type LLMProviderType,
} from '@node-gen-web/shared';

interface ProviderFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  providerId?: number;
}

type FormData = Omit<LLMProviderConfig, 'baseUrl'> & {
  baseUrl: string;
};

export function ProviderFormDialog({
  open,
  onOpenChange,
  providerId,
}: ProviderFormDialogProps) {
  const isEditing = !!providerId;
  const { data: existingProvider, isLoading: isLoadingProvider } = useLLMProvider(providerId);
  const createProvider = useCreateProvider();
  const updateProvider = useUpdateProvider();
  const queryClient = useQueryClient();
  const prevTypeRef = useRef<string>('openai');

  // Form schema: apiKey not required for Ollama or when editing
  const formSchema = LLMProviderConfigSchema.innerType().extend({
    baseUrl: z.string().url().or(z.literal('')).optional(),
    apiKey: z.string().optional().or(z.literal('')),
  });

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: '',
      type: 'openai',
      baseUrl: '',
      apiKey: '',
      model: '',
      temperature: 70,
      maxRetries: 3,
      isActive: false,
    },
  });

  const selectedType = watch('type');
  const temperature = watch('temperature');
  const maxRetries = watch('maxRetries');
  const isActive = watch('isActive');
  const baseUrl = watch('baseUrl');
  const isOllama = selectedType === 'ollama';

  // Fetch Ollama models when type is ollama and baseUrl is valid
  const ollamaBaseUrl = isOllama && baseUrl ? baseUrl : undefined;
  const {
    data: ollamaModels,
    isLoading: isLoadingModels,
    error: ollamaModelsError,
  } = useOllamaModels(ollamaBaseUrl);

  // Clear model when provider type changes
  useEffect(() => {
    if (prevTypeRef.current !== selectedType) {
      setValue('model', '');
      prevTypeRef.current = selectedType;
    }
  }, [selectedType, setValue]);

  // Load existing provider data when editing
  useEffect(() => {
    if (existingProvider && isEditing) {
      reset({
        name: existingProvider.name,
        type: existingProvider.type,
        baseUrl: existingProvider.baseUrl || '',
        apiKey: '', // Don't pre-fill API key for security
        model: existingProvider.model,
        temperature: existingProvider.temperature,
        maxRetries: existingProvider.maxRetries,
        isActive: existingProvider.isActive,
      });
    }
  }, [existingProvider, isEditing, reset]);

  // Reset form when dialog closes
  useEffect(() => {
    if (!open) {
      reset({
        name: '',
        type: 'openai',
        baseUrl: '',
        apiKey: '',
        model: '',
        temperature: 70,
        maxRetries: 3,
        isActive: false,
      });
    }
  }, [open, reset]);

  const onSubmit = async (data: FormData) => {
    // Client-side validation for non-Ollama providers
    if (data.type !== 'ollama' && !isEditing && !data.apiKey) {
      toast.error('API key is required for this provider type');
      return;
    }
    if (data.type === 'ollama' && !data.baseUrl) {
      toast.error('Ollama Server URL is required');
      return;
    }

    try {
      const payload: any = {
        ...data,
        baseUrl: data.baseUrl || null,
      };

      // Strip apiKey for Ollama
      if (data.type === 'ollama') {
        delete payload.apiKey;
      }

      if (isEditing && providerId) {
        // When editing, only include apiKey if it was changed
        const updates = data.apiKey
          ? payload
          : { ...payload, apiKey: undefined };

        await updateProvider.mutateAsync({
          id: providerId,
          updates,
        });
        toast.success('Provider updated successfully');
      } else {
        await createProvider.mutateAsync(payload);
        toast.success('Provider created successfully');
      }

      onOpenChange(false);
    } catch (error) {
      toast.error(
        `Failed to ${isEditing ? 'update' : 'create'} provider: ${
          error instanceof Error ? error.message : 'Unknown error'
        }`
      );
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {isEditing ? 'Edit Provider' : 'Add New Provider'}
          </DialogTitle>
          <DialogDescription>
            {isEditing
              ? 'Update the configuration for this LLM provider.'
              : 'Configure a new LLM provider for content generation.'}
          </DialogDescription>
        </DialogHeader>

        {isLoadingProvider && isEditing ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        ) : (
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="name">Name *</Label>
                <Input
                  id="name"
                  placeholder="My OpenAI Provider"
                  {...register('name')}
                />
                {errors.name && (
                  <p className="text-sm text-destructive">{errors.name.message}</p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="type">Provider Type *</Label>
                <Select
                  value={selectedType}
                  onValueChange={(value) => setValue('type', value as LLMProviderType)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="openai">OpenAI</SelectItem>
                    <SelectItem value="openrouter">OpenRouter</SelectItem>
                    <SelectItem value="anthropic">Anthropic</SelectItem>
                    <SelectItem value="ollama">Ollama</SelectItem>
                  </SelectContent>
                </Select>
                {errors.type && (
                  <p className="text-sm text-destructive">{errors.type.message}</p>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="baseUrl">
                {isOllama ? 'Ollama Server URL *' : 'Base URL (optional)'}
              </Label>
              <Input
                id="baseUrl"
                placeholder={isOllama ? 'http://192.168.1.100:11434' : 'https://api.openai.com/v1'}
                {...register('baseUrl')}
              />
              {errors.baseUrl && (
                <p className="text-sm text-destructive">{errors.baseUrl.message}</p>
              )}
              <p className="text-xs text-muted-foreground">
                {isOllama
                  ? 'The address of your Ollama server (e.g. http://localhost:11434).'
                  : 'Leave empty to use the default URL for the selected provider type.'}
              </p>
            </div>

            {!isOllama && (
              <div className="space-y-2">
                <Label htmlFor="apiKey">
                  API Key {isEditing ? '(leave empty to keep current)' : '*'}
                </Label>
                <Input
                  id="apiKey"
                  type="password"
                  placeholder={isEditing ? '••••••••' : 'sk-...'}
                  {...register('apiKey')}
                />
                {errors.apiKey && (
                  <p className="text-sm text-destructive">{errors.apiKey.message}</p>
                )}
                <p className="text-xs text-muted-foreground">
                  Your API key will be encrypted and stored securely.
                </p>
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="model">Model *</Label>
              {isOllama ? (
                <div className="flex gap-2">
                  <Select
                    value={watch('model')}
                    onValueChange={(value) => setValue('model', value)}
                    disabled={!ollamaModels?.length}
                  >
                    <SelectTrigger className="flex-1">
                      <SelectValue
                        placeholder={
                          isLoadingModels
                            ? 'Loading models...'
                            : ollamaModelsError
                              ? 'Server unreachable'
                              : !baseUrl
                                ? 'Enter server URL first'
                                : 'Select a model'
                        }
                      />
                    </SelectTrigger>
                    <SelectContent>
                      {(ollamaModels || []).map((model) => (
                        <SelectItem key={model} value={model}>
                          {model}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Button
                    type="button"
                    variant="outline"
                    size="icon"
                    disabled={!baseUrl || isLoadingModels}
                    onClick={() =>
                      queryClient.invalidateQueries({
                        queryKey: ['ollama-models', baseUrl],
                      })
                    }
                    title="Refresh models"
                  >
                    <RefreshCw
                      className={`h-4 w-4 ${isLoadingModels ? 'animate-spin' : ''}`}
                    />
                  </Button>
                </div>
              ) : (
                <Input
                  id="model"
                  placeholder="gpt-4o, claude-3-5-sonnet-20241022, etc."
                  {...register('model')}
                />
              )}
              {errors.model && (
                <p className="text-sm text-destructive">{errors.model.message}</p>
              )}
              {isOllama && ollamaModelsError && (
                <p className="text-sm text-destructive">
                  {ollamaModelsError instanceof Error
                    ? ollamaModelsError.message
                    : 'Failed to connect to Ollama server'}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="temperature">Temperature: {temperature}</Label>
                <span className="text-sm text-muted-foreground">
                  {(temperature / 100).toFixed(2)}
                </span>
              </div>
              <Slider
                id="temperature"
                min={0}
                max={100}
                step={1}
                value={[temperature]}
                onValueChange={(value) => setValue('temperature', value[0])}
              />
              <p className="text-xs text-muted-foreground">
                Controls randomness in generation. Lower = more focused, higher = more creative.
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="maxRetries">Max Retries: {maxRetries}</Label>
              </div>
              <Slider
                id="maxRetries"
                min={0}
                max={10}
                step={1}
                value={[maxRetries]}
                onValueChange={(value) => setValue('maxRetries', value[0])}
              />
              <p className="text-xs text-muted-foreground">
                Number of times to retry failed API calls.
              </p>
            </div>

            <div className="flex items-center gap-3">
              <Checkbox
                id="isActive"
                checked={isActive}
                onCheckedChange={(checked) =>
                  setValue('isActive', checked as boolean)
                }
              />
              <Label htmlFor="isActive" className="text-sm font-normal">
                Set as active provider
              </Label>
            </div>

            <div className="flex justify-end gap-3 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => onOpenChange(false)}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    {isEditing ? 'Updating...' : 'Creating...'}
                  </>
                ) : (
                  <>{isEditing ? 'Update' : 'Create'} Provider</>
                )}
              </Button>
            </div>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
