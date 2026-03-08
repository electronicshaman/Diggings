import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { CARD_TYPES, CARD_RARITIES, CARD_OWNERS } from '@atlas/shared'
import type { Card } from '@atlas/shared'
import { useCards } from '@/hooks/useCards'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card as UICard, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

export function CardListPage() {
  const [cardType, setCardType] = useState<string | undefined>()
  const [rarity, setRarity] = useState<string | undefined>()
  const [cardOwner, setCardOwner] = useState<string | undefined>()

  const { data, isLoading, error } = useCards({ cardType, rarity, cardOwner })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Cards</h1>
          <p className="text-muted-foreground">Browse and manage forge cards</p>
        </div>
        <Button asChild>
          <Link to="/cards/create">
            <Plus className="size-4" />
            Create Card
          </Link>
        </Button>
      </div>

      <UICard>
        <CardContent className="p-4">
          <div className="flex flex-wrap items-end gap-4">
            <div className="w-[160px]">
              <Label className="text-sm font-medium mb-1.5 block">Type</Label>
              <Select
                value={cardType ?? 'all'}
                onValueChange={(v) => setCardType(v === 'all' ? undefined : v)}
              >
                <SelectTrigger><SelectValue placeholder="All types" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All types</SelectItem>
                  {CARD_TYPES.map((t) => (
                    <SelectItem key={t} value={t}>{t}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="w-[160px]">
              <Label className="text-sm font-medium mb-1.5 block">Rarity</Label>
              <Select
                value={rarity ?? 'all'}
                onValueChange={(v) => setRarity(v === 'all' ? undefined : v)}
              >
                <SelectTrigger><SelectValue placeholder="All rarities" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All rarities</SelectItem>
                  {CARD_RARITIES.map((r) => (
                    <SelectItem key={r} value={r}>{r}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="w-[160px]">
              <Label className="text-sm font-medium mb-1.5 block">Owner</Label>
              <Select
                value={cardOwner ?? 'all'}
                onValueChange={(v) => setCardOwner(v === 'all' ? undefined : v)}
              >
                <SelectTrigger><SelectValue placeholder="All owners" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All owners</SelectItem>
                  {CARD_OWNERS.map((o) => (
                    <SelectItem key={o} value={o}>{o}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </UICard>

      {isLoading && <CardGridSkeleton />}

      {error && (
        <UICard>
          <CardContent className="p-8 text-center">
            <p className="text-destructive">
              Failed to load cards: {error instanceof Error ? error.message : 'Unknown error'}
            </p>
          </CardContent>
        </UICard>
      )}

      {!isLoading && !error && data?.cards.length === 0 && (
        <UICard>
          <CardContent className="p-8 text-center">
            <p className="text-muted-foreground">No cards yet. Create your first card to get started.</p>
          </CardContent>
        </UICard>
      )}

      {!isLoading && !error && data && data.cards.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {data.cards.map((card) => (
            <CardGridItem key={card.id} card={card} />
          ))}
        </div>
      )}
    </div>
  )
}

function CardGridItem({ card }: { card: Card }) {
  return (
    <Link to={`/cards/${card.id}`}>
      <UICard className="h-full transition-colors hover:bg-muted/50">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg line-clamp-1">{card.name}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <div className="flex flex-wrap gap-1.5">
            <Badge variant="secondary">{card.cardType}</Badge>
            <Badge variant="outline">{card.rarity}</Badge>
            <Badge variant="outline">{card.cardOwner}</Badge>
          </div>
          {card.description && (
            <p className="text-xs text-muted-foreground line-clamp-2">{card.description}</p>
          )}
        </CardContent>
      </UICard>
    </Link>
  )
}

function CardGridSkeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {Array.from({ length: 8 }).map((_, i) => (
        <UICard key={i}>
          <CardHeader className="pb-2">
            <Skeleton className="h-6 w-3/4" />
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex gap-1.5">
              <Skeleton className="h-5 w-16" />
              <Skeleton className="h-5 w-16" />
              <Skeleton className="h-5 w-16" />
            </div>
          </CardContent>
        </UICard>
      ))}
    </div>
  )
}
