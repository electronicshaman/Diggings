import { useState } from "react"
import { useParams, Link, useNavigate } from "react-router-dom"
import { ArrowLeft, Pencil, Trash2 } from "lucide-react"
import {
  NodeType,
  NodeTypeDisplayNames,
  BiomeDisplayNames,
  ActNames,
  type AnyNodeMetadata,
  type Act,
} from "@node-gen-web/shared"
import { useNode } from "@/hooks/useNodes"
import { useDeleteNode } from "@/hooks/useNodeMutations"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Skeleton } from "@/components/ui/skeleton"
import { Separator } from "@/components/ui/separator"

function MetadataRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-3 gap-4 py-2">
      <dt className="text-sm font-medium text-muted-foreground">{label}</dt>
      <dd className="col-span-2 text-sm">{children}</dd>
    </div>
  )
}

function ArrayBadges({ items, variant = "secondary" }: { items: string[]; variant?: "default" | "secondary" | "outline" }) {
  if (!items.length) return <span className="text-muted-foreground">None</span>
  return (
    <div className="flex flex-wrap gap-1">
      {items.map((item) => (
        <Badge key={item} variant={variant}>{item}</Badge>
      ))}
    </div>
  )
}

function TypeSpecificMetadata({ node }: { node: AnyNodeMetadata }) {
  switch (node.type) {
    case NodeType.Combat:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">Combat-Specific</h4>
          <MetadataRow label="Enemy Type Hooks">
            <ArrayBadges items={node.enemyTypeHooks} />
          </MetadataRow>
          <MetadataRow label="Environmental Context">{node.environmentalContext}</MetadataRow>
          <MetadataRow label="Combat Difficulty">{node.estimatedCombatDifficulty}/5</MetadataRow>
        </>
      )
    case NodeType.Choice:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">Choice-Specific</h4>
          <MetadataRow label="Consequence Hooks">
            <ArrayBadges items={node.consequenceHooks} />
          </MetadataRow>
          <MetadataRow label="Dilemma Type">
            <Badge variant="outline">{node.dilemmaType}</Badge>
          </MetadataRow>
        </>
      )
    case NodeType.Trade:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">Trade-Specific</h4>
          <MetadataRow label="Trader Archetype">{node.traderArchetype}</MetadataRow>
          <MetadataRow label="Pricing Hooks">
            <ArrayBadges items={node.pricingHooks} />
          </MetadataRow>
        </>
      )
    case NodeType.Rest:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">Rest-Specific</h4>
          <MetadataRow label="Rest Type">
            <Badge variant="outline">{node.restType}</Badge>
          </MetadataRow>
          <MetadataRow label="Interruption Chance">
            <Badge variant="outline">{node.interruptionChance}</Badge>
          </MetadataRow>
          {node.dreamHooks && (
            <MetadataRow label="Dream Hooks">
              <ArrayBadges items={node.dreamHooks} />
            </MetadataRow>
          )}
        </>
      )
    case NodeType.Passage:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">Passage-Specific</h4>
          <MetadataRow label="Travel Event Hooks">
            <ArrayBadges items={node.travelEventHooks} />
          </MetadataRow>
          <MetadataRow label="Environmental Storytelling">{node.environmentalStorytelling}</MetadataRow>
          <MetadataRow label="Resource Cost">
            {node.resourceCost.type}: {node.resourceCost.amount}
            {node.resourceCost.optional && " (optional)"}
          </MetadataRow>
        </>
      )
    case NodeType.StateCheck:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">State Check-Specific</h4>
          <MetadataRow label="Condition Hooks">
            <ArrayBadges items={node.conditionHooks} />
          </MetadataRow>
          <MetadataRow label="Branch Targets">
            <div className="space-y-1">
              <div>Success: <code className="text-xs bg-muted px-1 rounded">{node.branchTargets.success}</code></div>
              <div>Failure: <code className="text-xs bg-muted px-1 rounded">{node.branchTargets.failure}</code></div>
            </div>
          </MetadataRow>
        </>
      )
    case NodeType.Transition:
      return (
        <>
          <Separator />
          <h4 className="font-medium text-sm pt-2">Transition-Specific</h4>
          {node.actChangeTrigger && (
            <MetadataRow label="Act Change Trigger">
              <Badge>{ActNames[node.actChangeTrigger]}</Badge>
            </MetadataRow>
          )}
          <MetadataRow label="Narrative Summary">{node.narrativeSummary}</MetadataRow>
          <MetadataRow label="World State Shifts">
            <ArrayBadges items={node.worldStateShifts} />
          </MetadataRow>
        </>
      )
    default:
      return null
  }
}

function LoadingSkeleton() {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Skeleton className="h-4 w-24" />
      </div>
      <div className="flex items-center justify-between">
        <div className="space-y-2">
          <Skeleton className="h-8 w-64" />
          <div className="flex gap-2">
            <Skeleton className="h-5 w-16" />
            <Skeleton className="h-5 w-20" />
            <Skeleton className="h-5 w-12" />
          </div>
        </div>
        <div className="flex gap-2">
          <Skeleton className="h-9 w-20" />
          <Skeleton className="h-9 w-20" />
        </div>
      </div>
      <Skeleton className="h-10 w-80" />
      <Card>
        <CardContent className="pt-6 space-y-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="grid grid-cols-3 gap-4">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-48 col-span-2" />
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  )
}

export function NodeDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: node, isLoading, error } = useNode(id)
  const deleteNode = useDeleteNode()
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

  const handleDelete = async () => {
    if (!id) return
    try {
      await deleteNode.mutateAsync(id)
      navigate("/nodes")
    } catch {
      // Error handling is done by the mutation
    }
  }

  if (isLoading) {
    return <LoadingSkeleton />
  }

  if (error || !node) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Link
            to="/nodes"
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="size-4" />
            Back to nodes
          </Link>
        </div>
        <Card>
          <CardHeader>
            <CardTitle className="text-destructive">Node Not Found</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground">
              {error instanceof Error ? error.message : `Could not find node with ID: ${id}`}
            </p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link
          to="/nodes"
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
          Back to nodes
        </Link>
      </div>

      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <h1 className="text-2xl font-bold">{node.name}</h1>
          <div className="flex flex-wrap gap-2">
            <Badge>{NodeTypeDisplayNames[node.type]}</Badge>
            <Badge variant="secondary">{BiomeDisplayNames[node.biome]}</Badge>
            {node.acts.map((act) => (
              <Badge key={act} variant="outline">Act {act}: {ActNames[act as Act]}</Badge>
            ))}
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" asChild>
            <Link to={`/nodes/${id}/edit`}>
              <Pencil className="size-4 mr-2" />
              Edit
            </Link>
          </Button>
          <Button variant="destructive" onClick={() => setDeleteDialogOpen(true)}>
            <Trash2 className="size-4 mr-2" />
            Delete
          </Button>
        </div>
      </div>

      <Tabs defaultValue="metadata">
        <TabsList>
          <TabsTrigger value="metadata">Metadata</TabsTrigger>
          <TabsTrigger value="eligibility">Eligibility</TabsTrigger>
          <TabsTrigger value="content">Content</TabsTrigger>
        </TabsList>

        <TabsContent value="metadata">
          <Card>
            <CardHeader>
              <CardTitle>Node Metadata</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="divide-y">
                <MetadataRow label="ID">
                  <code className="text-xs bg-muted px-2 py-1 rounded">{node.id}</code>
                </MetadataRow>
                <MetadataRow label="Type">
                  <Badge>{NodeTypeDisplayNames[node.type]}</Badge>
                </MetadataRow>
                <MetadataRow label="Biome">
                  <Badge variant="secondary">{BiomeDisplayNames[node.biome]}</Badge>
                </MetadataRow>
                <MetadataRow label="Acts">
                  <div className="flex flex-wrap gap-1">
                    {node.acts.map((act) => (
                      <Badge key={act} variant="outline">Act {act}: {ActNames[act as Act]}</Badge>
                    ))}
                  </div>
                </MetadataRow>
                <MetadataRow label="Is Replaceable">
                  <Badge variant={node.isReplaceable ? "default" : "secondary"}>
                    {node.isReplaceable ? "Yes" : "No"}
                  </Badge>
                </MetadataRow>
                <MetadataRow label="Replacement Tags">
                  <ArrayBadges items={node.replacementTags} />
                </MetadataRow>
                <MetadataRow label="Themes">
                  <ArrayBadges items={node.themes} />
                </MetadataRow>
                <MetadataRow label="Entity Types">
                  <ArrayBadges items={node.entityTypes} />
                </MetadataRow>
                {node.estimatedCombatDifficulty && node.type !== NodeType.Combat && (
                  <MetadataRow label="Est. Combat Difficulty">{node.estimatedCombatDifficulty}/5</MetadataRow>
                )}
                {node.resourceCost && node.type !== NodeType.Passage && (
                  <MetadataRow label="Resource Cost">
                    {node.resourceCost.type}: {node.resourceCost.amount}
                    {node.resourceCost.optional && " (optional)"}
                  </MetadataRow>
                )}
                {node.potentialRewards && (
                  <MetadataRow label="Potential Rewards">
                    <ArrayBadges items={node.potentialRewards} />
                  </MetadataRow>
                )}
                <MetadataRow label="Act Variant">
                  <Badge variant={node.actVariant ? "default" : "secondary"}>
                    {node.actVariant ? "Yes" : "No"}
                  </Badge>
                </MetadataRow>
              </dl>
              <TypeSpecificMetadata node={node} />
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="eligibility">
          <Card>
            <CardHeader>
              <CardTitle>Eligibility Criteria</CardTitle>
            </CardHeader>
            <CardContent>
              {node.eligibility ? (
                <pre className="text-sm bg-muted p-4 rounded-lg overflow-auto max-h-[600px]">
                  {JSON.stringify(node.eligibility, null, 2)}
                </pre>
              ) : (
                <p className="text-muted-foreground">No eligibility criteria defined</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="content">
          <Card>
            <CardHeader>
              <CardTitle>Content</CardTitle>
            </CardHeader>
            <CardContent>
              {node.actVariants ? (
                <div className="space-y-4">
                  <h4 className="font-medium">Act Variants</h4>
                  <pre className="text-sm bg-muted p-4 rounded-lg overflow-auto max-h-[600px]">
                    {JSON.stringify(node.actVariants, null, 2)}
                  </pre>
                </div>
              ) : node.content ? (
                <div className="space-y-4">
                  <h4 className="font-medium">Node Content</h4>
                  <pre className="text-sm bg-muted p-4 rounded-lg overflow-auto max-h-[600px]">
                    {JSON.stringify(node.content, null, 2)}
                  </pre>
                </div>
              ) : (
                <p className="text-muted-foreground">No content defined yet</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Node</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete "{node.name}"? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteNode.isPending}
            >
              {deleteNode.isPending ? "Deleting..." : "Delete"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
