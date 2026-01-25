import { useState } from 'react';
import { Sparkles, Wand2, Boxes } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { QuickGenerate, AssistedCreate, BulkGenerate } from '@/components/generation';

type GenerateTab = 'quick' | 'assisted' | 'bulk';

export default function GeneratePage() {
  const [activeTab, setActiveTab] = useState<GenerateTab>('quick');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">AI Generation</h1>
        <p className="text-muted-foreground">
          Generate narrative content using AI. Choose quick generation for minimal input, assisted
          for hybrid mode, or bulk to fill distribution gaps.
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as GenerateTab)}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="quick" className="gap-2">
            <Sparkles className="size-4" />
            <span className="hidden sm:inline">Quick</span>
          </TabsTrigger>
          <TabsTrigger value="assisted" className="gap-2">
            <Wand2 className="size-4" />
            <span className="hidden sm:inline">Assisted</span>
          </TabsTrigger>
          <TabsTrigger value="bulk" className="gap-2">
            <Boxes className="size-4" />
            <span className="hidden sm:inline">Bulk</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="quick" className="mt-6">
          <QuickGenerate />
        </TabsContent>

        <TabsContent value="assisted" className="mt-6">
          <AssistedCreate />
        </TabsContent>

        <TabsContent value="bulk" className="mt-6">
          <BulkGenerate />
        </TabsContent>
      </Tabs>
    </div>
  );
}
