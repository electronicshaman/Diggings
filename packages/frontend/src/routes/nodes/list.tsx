import { useState, useEffect, useMemo } from "react"
import { Link, useNavigate } from "react-router-dom"
import { Plus, RotateCcw, LayoutGrid, List, Search } from "lucide-react"
import {
  NodeType,
  ALL_NODE_TYPES,
  NodeTypeDisplayNames,
  Biome,
  ALL_BIOMES,
  BiomeDisplayNames,
  ALL_ACTS,
  ActNames,
  type Act,
  type AnyNodeMetadata,
} from "@node-gen-web/shared"
import { useNodes } from "@/hooks/useNodes"
import { useUIStore } from "@/store/ui-store"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Checkbox } from "@/components/ui/checkbox"
import { Skeleton } from "@/components/ui/skeleton"
import { Separator } from "@/components/ui/separator"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Label } from "@/components/ui/label"

export function NodeListPage() {
  const navigate = useNavigate()
  const { filters, viewMode, setFilters, resetFilters, setViewMode } = useUIStore()

  const [searchInput, setSearchInput] = useState(filters.search ?? "")

  useEffect(() => {
    const timer = setTimeout(() => {
      setFilters({ search: searchInput || undefined })
    }, 300)
    return () => clearTimeout(timer)
  }, [searchInput, setFilters])

  const queryFilters = useMemo(() => ({
    type: filters.type as NodeType | undefined,
    biome: filters.biome as Biome | undefined,
    acts: filters.acts as Act[] | undefined,
  }), [filters.type, filters.biome, filters.acts])

  const { data, isLoading, error } = useNodes(queryFilters)

  const filteredNodes = useMemo(() => {
    if (!data?.nodes) return []
    if (!filters.search) return data.nodes
    const searchLower = filters.search.toLowerCase()
    return data.nodes.filter((node) =>
      node.name.toLowerCase().includes(searchLower) ||
      node.id.toLowerCase().includes(searchLower)
    )
  }, [data?.nodes, filters.search])

  const handleActToggle = (act: Act, checked: boolean) => {
    const currentActs = filters.acts ?? []
    const newActs = checked
      ? [...currentActs, act]
      : currentActs.filter((a) => a !== act)
    setFilters({ acts: newActs.length > 0 ? newActs : undefined })
  }

  const handleReset = () => {
    resetFilters()
    setSearchInput("")
  }

  const hasActiveFilters = filters.type || filters.biome || filters.acts?.length || filters.search

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Nodes</h1>
          <p className="text-muted-foreground">
            Browse and manage your game nodes
          </p>
        </div>
        <Button asChild>
          <Link to="/nodes/create">
            <Plus className="size-4" />
            Create Node
          </Link>
        </Button>
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="flex flex-wrap items-end gap-4">
            <div className="flex-1 min-w-[200px]">
              <Label htmlFor="search" className="text-sm font-medium mb-1.5 block">
                Search
              </Label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
                <Input
                  id="search"
                  placeholder="Search nodes..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  className="pl-9"
                />
              </div>
            </div>

            <div className="w-[160px]">
              <Label className="text-sm font-medium mb-1.5 block">Type</Label>
              <Select
                value={filters.type ?? "all"}
                onValueChange={(value) =>
                  setFilters({ type: value === "all" ? undefined : value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="All types" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All types</SelectItem>
                  {ALL_NODE_TYPES.map((type) => (
                    <SelectItem key={type} value={type}>
                      {NodeTypeDisplayNames[type]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="w-[160px]">
              <Label className="text-sm font-medium mb-1.5 block">Biome</Label>
              <Select
                value={filters.biome ?? "all"}
                onValueChange={(value) =>
                  setFilters({ biome: value === "all" ? undefined : value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="All biomes" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All biomes</SelectItem>
                  {ALL_BIOMES.map((biome) => (
                    <SelectItem key={biome} value={biome}>
                      {BiomeDisplayNames[biome]}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label className="text-sm font-medium mb-1.5 block">Acts</Label>
              <div className="flex items-center gap-3 h-10">
                {ALL_ACTS.map((act) => (
                  <div key={act} className="flex items-center gap-1.5">
                    <Checkbox
                      id={`act-${act}`}
                      checked={filters.acts?.includes(act) ?? false}
                      onCheckedChange={(checked) =>
                        handleActToggle(act, checked === true)
                      }
                    />
                    <Label htmlFor={`act-${act}`} className="text-sm cursor-pointer">
                      {act}
                    </Label>
                  </div>
                ))}
              </div>
            </div>

            <Separator orientation="vertical" className="h-10 hidden sm:block" />

            <div className="flex items-center gap-2">
              <Button
                variant={viewMode === "cards" ? "default" : "outline"}
                size="icon"
                onClick={() => setViewMode("cards")}
                title="Cards view"
              >
                <LayoutGrid className="size-4" />
              </Button>
              <Button
                variant={viewMode === "table" ? "default" : "outline"}
                size="icon"
                onClick={() => setViewMode("table")}
                title="Table view"
              >
                <List className="size-4" />
              </Button>
            </div>

            {hasActiveFilters && (
              <Button variant="ghost" onClick={handleReset} className="gap-1.5">
                <RotateCcw className="size-4" />
                Reset
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {isLoading && <LoadingSkeleton viewMode={viewMode} />}

      {error && (
        <Card>
          <CardContent className="p-8 text-center">
            <p className="text-destructive">
              Failed to load nodes: {error instanceof Error ? error.message : "Unknown error"}
            </p>
          </CardContent>
        </Card>
      )}

      {!isLoading && !error && filteredNodes.length === 0 && (
        <Card>
          <CardContent className="p-8 text-center">
            <p className="text-muted-foreground">
              {hasActiveFilters
                ? "No nodes match your filters."
                : "No nodes yet. Create your first node to get started."}
            </p>
            {hasActiveFilters && (
              <Button variant="link" onClick={handleReset} className="mt-2">
                Clear filters
              </Button>
            )}
          </CardContent>
        </Card>
      )}

      {!isLoading && !error && filteredNodes.length > 0 && (
        viewMode === "cards" ? (
          <NodesGrid nodes={filteredNodes} />
        ) : (
          <NodesTable nodes={filteredNodes} onRowClick={(id) => navigate(`/nodes/${id}`)} />
        )
      )}
    </div>
  )
}

function NodesGrid({ nodes }: { nodes: AnyNodeMetadata[] }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {nodes.map((node) => (
        <Link key={node.id} to={`/nodes/${node.id}`}>
          <Card className="h-full transition-colors hover:bg-muted/50">
            <CardHeader className="pb-2">
              <CardTitle className="text-lg line-clamp-1">{node.name}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex flex-wrap gap-1.5">
                <Badge variant="secondary">
                  {NodeTypeDisplayNames[node.type]}
                </Badge>
                <Badge variant="outline">
                  {BiomeDisplayNames[node.biome]}
                </Badge>
              </div>
              <div className="flex flex-wrap gap-1">
                {node.acts.map((act) => (
                  <Badge key={act} variant="outline" className="text-xs">
                    Act {act}: {ActNames[act]}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        </Link>
      ))}
    </div>
  )
}

function NodesTable({
  nodes,
  onRowClick,
}: {
  nodes: AnyNodeMetadata[]
  onRowClick: (id: string) => void
}) {
  return (
    <Card>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>ID</TableHead>
            <TableHead>Name</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Biome</TableHead>
            <TableHead>Acts</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {nodes.map((node) => (
            <TableRow
              key={node.id}
              className="cursor-pointer"
              onClick={() => onRowClick(node.id)}
            >
              <TableCell className="font-mono text-xs">{node.id}</TableCell>
              <TableCell className="font-medium">{node.name}</TableCell>
              <TableCell>
                <Badge variant="secondary">
                  {NodeTypeDisplayNames[node.type]}
                </Badge>
              </TableCell>
              <TableCell>
                <Badge variant="outline">
                  {BiomeDisplayNames[node.biome]}
                </Badge>
              </TableCell>
              <TableCell>
                <div className="flex gap-1">
                  {node.acts.map((act) => (
                    <Badge key={act} variant="outline" className="text-xs">
                      {act}
                    </Badge>
                  ))}
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Card>
  )
}

function LoadingSkeleton({ viewMode }: { viewMode: "cards" | "table" }) {
  if (viewMode === "cards") {
    return (
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <Card key={i}>
            <CardHeader className="pb-2">
              <Skeleton className="h-6 w-3/4" />
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex gap-1.5">
                <Skeleton className="h-5 w-16" />
                <Skeleton className="h-5 w-20" />
              </div>
              <div className="flex gap-1">
                <Skeleton className="h-5 w-12" />
                <Skeleton className="h-5 w-12" />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    )
  }

  return (
    <Card>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>ID</TableHead>
            <TableHead>Name</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Biome</TableHead>
            <TableHead>Acts</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {Array.from({ length: 8 }).map((_, i) => (
            <TableRow key={i}>
              <TableCell><Skeleton className="h-4 w-24" /></TableCell>
              <TableCell><Skeleton className="h-4 w-32" /></TableCell>
              <TableCell><Skeleton className="h-5 w-16" /></TableCell>
              <TableCell><Skeleton className="h-5 w-20" /></TableCell>
              <TableCell>
                <div className="flex gap-1">
                  <Skeleton className="h-5 w-8" />
                  <Skeleton className="h-5 w-8" />
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Card>
  )
}
