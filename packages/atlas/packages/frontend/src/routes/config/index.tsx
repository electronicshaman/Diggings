import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useDistributions, useBiomes } from "@/hooks/useConfig"
import { useNodeStats } from "@/hooks/useNodes"
import {
  BiomeDisplayNames,
  ALL_BIOMES,
  NodeTypeDisplayNames,
  ALL_NODE_TYPES,
  BIOME_DISTRIBUTIONS,
} from "@node-gen-web/shared"

function DistributionsMatrix() {
  const { isLoading } = useDistributions()
  const { data: stats } = useNodeStats()

  if (isLoading) {
    return <Skeleton className="h-[400px] w-full" />
  }

  const actualByBiomeAndType: Record<string, Record<string, number>> = {}
  if (stats) {
    ALL_BIOMES.forEach((biome) => {
      actualByBiomeAndType[biome] = {}
      ALL_NODE_TYPES.forEach((type) => {
        actualByBiomeAndType[biome][type] = 0
      })
    })
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Target Node Distribution</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[140px]">Biome</TableHead>
                {ALL_NODE_TYPES.map((type) => (
                  <TableHead key={type} className="text-center w-[100px]">
                    {NodeTypeDisplayNames[type]}
                  </TableHead>
                ))}
                <TableHead className="text-center w-[80px]">Total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {ALL_BIOMES.map((biome) => {
                const dist = BIOME_DISTRIBUTIONS[biome]
                const total = Object.values(dist).reduce((sum, n) => sum + n, 0)
                return (
                  <TableRow key={biome}>
                    <TableCell className="font-medium">
                      {BiomeDisplayNames[biome]}
                    </TableCell>
                    {ALL_NODE_TYPES.map((type) => (
                      <TableCell key={type} className="text-center">
                        {dist[type]}
                      </TableCell>
                    ))}
                    <TableCell className="text-center font-semibold">
                      {total}
                    </TableCell>
                  </TableRow>
                )
              })}
              <TableRow className="bg-muted/50 font-semibold">
                <TableCell>Total</TableCell>
                {ALL_NODE_TYPES.map((type) => {
                  const typeTotal = ALL_BIOMES.reduce(
                    (sum, biome) => sum + BIOME_DISTRIBUTIONS[biome][type],
                    0
                  )
                  return (
                    <TableCell key={type} className="text-center">
                      {typeTotal}
                    </TableCell>
                  )
                })}
                <TableCell className="text-center">
                  {ALL_BIOMES.reduce((sum, biome) => {
                    const dist = BIOME_DISTRIBUTIONS[biome]
                    return sum + Object.values(dist).reduce((s, n) => s + n, 0)
                  }, 0)}
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  )
}

function CurrentStats() {
  const { data: stats, isLoading } = useNodeStats()

  if (isLoading) {
    return <Skeleton className="h-[300px] w-full" />
  }

  if (!stats) {
    return (
      <Card>
        <CardContent className="p-8 text-center text-muted-foreground">
          No stats available
        </CardContent>
      </Card>
    )
  }

  const targetsByType: Record<string, number> = {}
  ALL_NODE_TYPES.forEach((type) => {
    targetsByType[type] = ALL_BIOMES.reduce(
      (sum, biome) => sum + BIOME_DISTRIBUTIONS[biome][type],
      0
    )
  })

  const targetsByBiome: Record<string, number> = {}
  ALL_BIOMES.forEach((biome) => {
    const dist = BIOME_DISTRIBUTIONS[biome]
    targetsByBiome[biome] = Object.values(dist).reduce((sum, n) => sum + n, 0)
  })

  const grandTotal = Object.values(targetsByBiome).reduce((sum, n) => sum + n, 0)

  return (
    <Card>
      <CardHeader>
        <CardTitle>Current Stats vs Targets</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex items-center gap-4">
          <span className="text-lg font-medium">Total Nodes:</span>
          <span
            className={
              stats.total >= grandTotal ? "text-green-600" : "text-red-600"
            }
          >
            {stats.total} / {grandTotal}
          </span>
        </div>

        <div>
          <h4 className="text-sm font-medium mb-3">By Type</h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {ALL_NODE_TYPES.map((type) => {
              const actual = stats.byType[type] ?? 0
              const target = targetsByType[type]
              const atTarget = actual >= target
              return (
                <div
                  key={type}
                  className={`p-3 rounded-lg border ${
                    atTarget ? "border-green-200 bg-green-50" : "border-red-200 bg-red-50"
                  }`}
                >
                  <div className="text-xs text-muted-foreground">
                    {NodeTypeDisplayNames[type]}
                  </div>
                  <div
                    className={`text-lg font-semibold ${
                      atTarget ? "text-green-700" : "text-red-700"
                    }`}
                  >
                    {actual} / {target}
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        <div>
          <h4 className="text-sm font-medium mb-3">By Biome</h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {ALL_BIOMES.map((biome) => {
              const actual = stats.byBiome[biome] ?? 0
              const target = targetsByBiome[biome]
              const atTarget = actual >= target
              return (
                <div
                  key={biome}
                  className={`p-3 rounded-lg border ${
                    atTarget ? "border-green-200 bg-green-50" : "border-red-200 bg-red-50"
                  }`}
                >
                  <div className="text-xs text-muted-foreground">
                    {BiomeDisplayNames[biome]}
                  </div>
                  <div
                    className={`text-lg font-semibold ${
                      atTarget ? "text-green-700" : "text-red-700"
                    }`}
                  >
                    {actual} / {target}
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

function BiomesList() {
  const { data: biomes, isLoading } = useBiomes()

  if (isLoading) {
    return (
      <div className="grid gap-4 md:grid-cols-2">
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} className="h-[200px]" />
        ))}
      </div>
    )
  }

  if (!biomes || biomes.length === 0) {
    return (
      <Card>
        <CardContent className="p-8 text-center text-muted-foreground">
          No biomes configured
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="grid gap-4 md:grid-cols-2">
      {biomes.map((biome) => (
        <Card key={biome.id}>
          <CardHeader>
            <CardTitle className="text-lg">{biome.name}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {biome.description && (
              <p className="text-sm text-muted-foreground">{biome.description}</p>
            )}
            {biome.themes && biome.themes.length > 0 && (
              <div>
                <span className="text-xs font-medium text-muted-foreground">
                  Themes
                </span>
                <div className="flex flex-wrap gap-1 mt-1">
                  {biome.themes.map((theme) => (
                    <Badge key={theme} variant="secondary" className="text-xs">
                      {theme}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      ))}
    </div>
  )
}

export function ConfigPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Configuration</h1>
        <p className="text-muted-foreground">
          View biome distributions and lookup tables
        </p>
      </div>

      <Tabs defaultValue="distributions" className="space-y-4">
        <TabsList>
          <TabsTrigger value="distributions">Distributions</TabsTrigger>
          <TabsTrigger value="stats">Current Stats</TabsTrigger>
          <TabsTrigger value="biomes">Biomes</TabsTrigger>
        </TabsList>

        <TabsContent value="distributions" className="space-y-4">
          <DistributionsMatrix />
        </TabsContent>

        <TabsContent value="stats" className="space-y-4">
          <CurrentStats />
        </TabsContent>

        <TabsContent value="biomes" className="space-y-4">
          <BiomesList />
        </TabsContent>
      </Tabs>
    </div>
  )
}
