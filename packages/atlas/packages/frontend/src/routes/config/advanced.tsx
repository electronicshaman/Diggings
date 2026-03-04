import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BeatRoleEditor } from '@/components/config/BeatRoleEditor';
import { BeatSequenceEditor } from '@/components/config/BeatSequenceEditor';
import { StyleGuideEditor } from '@/components/config/StyleGuideEditor';
import { VernacularEditor } from '@/components/config/VernacularEditor';
import { ActToneEditor } from '@/components/config/ActToneEditor';

export function AdvancedConfigPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Advanced Configuration</h1>
        <p className="text-muted-foreground">
          Manage beat roles, sequences, style guides, vernacular, and act tones
        </p>
      </div>

      <Tabs defaultValue="beat-roles" className="space-y-4">
        <TabsList>
          <TabsTrigger value="beat-roles">Beat Roles</TabsTrigger>
          <TabsTrigger value="beat-sequences">Beat Sequences</TabsTrigger>
          <TabsTrigger value="style-guides">Style Guides</TabsTrigger>
          <TabsTrigger value="vernacular">Vernacular</TabsTrigger>
          <TabsTrigger value="act-tones">Act Tones</TabsTrigger>
        </TabsList>

        <TabsContent value="beat-roles" className="space-y-4">
          <BeatRoleEditor />
        </TabsContent>

        <TabsContent value="beat-sequences" className="space-y-4">
          <BeatSequenceEditor />
        </TabsContent>

        <TabsContent value="style-guides" className="space-y-4">
          <StyleGuideEditor />
        </TabsContent>

        <TabsContent value="vernacular" className="space-y-4">
          <VernacularEditor />
        </TabsContent>

        <TabsContent value="act-tones" className="space-y-4">
          <ActToneEditor />
        </TabsContent>
      </Tabs>
    </div>
  );
}
