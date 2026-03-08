import { useState } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Pencil, Trash2 } from 'lucide-react'
import { useCard } from '@/hooks/useCards'
import { useDeleteCard } from '@/hooks/useCardMutations'
import { Card as UICard, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-3 gap-4 py-2">
      <dt className="text-sm font-medium text-muted-foreground">{label}</dt>
      <dd className="col-span-2 text-sm">{children}</dd>
    </div>
  )
}

export function CardDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: card, isLoading, error } = useCard(id)
  const { mutateAsync: deleteCard, isPending: isDeleting } = useDeleteCard()
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)

  if (isLoading) {
    return (
      <div className="space-y-4 max-w-3xl mx-auto">
        <Skeleton className="h-10 w-48" />
        <Skeleton className="h-48 w-full" />
      </div>
    )
  }

  if (error || !card) {
    return (
      <div className="text-center py-16">
        <p className="text-destructive">
          {error instanceof Error ? error.message : 'Card not found'}
        </p>
        <Button asChild variant="link" className="mt-2">
          <Link to="/cards">Back to cards</Link>
        </Button>
      </div>
    )
  }

  const handleDelete = async () => {
    await deleteCard(card.id)
    navigate('/cards')
  }

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link to="/cards"><ArrowLeft className="size-4" /></Link>
        </Button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold tracking-tight">{card.name}</h1>
          <div className="flex flex-wrap gap-1.5 mt-1">
            <Badge variant="secondary">{card.cardType}</Badge>
            <Badge variant="outline">{card.rarity}</Badge>
            <Badge variant="outline">{card.cardOwner}</Badge>
            <Badge variant="outline">{card.handling}</Badge>
            <Badge variant="outline">{card.accessibilityTier}</Badge>
          </div>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline">
            <Link to={`/cards/${card.id}/edit`}>
              <Pencil className="size-4 mr-1" /> Edit
            </Link>
          </Button>
          <Button variant="destructive" onClick={() => setShowDeleteDialog(true)}>
            <Trash2 className="size-4 mr-1" /> Delete
          </Button>
        </div>
      </div>

      <UICard>
        <CardHeader><CardTitle>Identity</CardTitle></CardHeader>
        <CardContent>
          <dl>
            <Row label="ID"><span className="font-mono text-xs">{card.id}</span></Row>
            <Row label="Description">{card.description || <span className="text-muted-foreground">—</span>}</Row>
          </dl>
        </CardContent>
      </UICard>

      <UICard>
        <CardHeader><CardTitle>Costs</CardTitle></CardHeader>
        <CardContent>
          {card.costs.length === 0 ? (
            <p className="text-sm text-muted-foreground">No costs (free to play)</p>
          ) : (
            <ul className="space-y-1">
              {card.costs.map((cost, i) => (
                <li key={i} className="text-sm">
                  <span className="font-medium capitalize">{cost.type}</span>: {cost.amount}
                  {cost.resourceKey && ` (${cost.resourceKey})`}
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </UICard>

      <UICard>
        <CardHeader><CardTitle>Effects</CardTitle></CardHeader>
        <CardContent>
          {card.effects.length === 0 ? (
            <p className="text-sm text-muted-foreground">No effects defined</p>
          ) : (
            <ul className="space-y-2">
              {card.effects.map((effect, i) => (
                <li key={i} className="text-sm">
                  <span className="font-medium font-mono">{effect.handlerId}</span>
                  {Object.keys(effect.params).length > 0 && (
                    <pre className="text-xs mt-1 text-muted-foreground">
                      {JSON.stringify(effect.params, null, 2)}
                    </pre>
                  )}
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </UICard>

      {card.classAffinity.length > 0 && (
        <UICard>
          <CardHeader><CardTitle>Class Affinity</CardTitle></CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-1.5">
              {card.classAffinity.map((c) => (
                <Badge key={c} variant="secondary">{c}</Badge>
              ))}
            </div>
          </CardContent>
        </UICard>
      )}

      {(card.flavorText || card.baseDurability != null || card.volatileBonus != null || card.luckModifier != null || card.enemyFaction) && (
        <UICard>
          <CardHeader><CardTitle>Optional Fields</CardTitle></CardHeader>
          <CardContent>
            <dl>
              {card.flavorText && <Row label="Flavor Text"><em>{card.flavorText}</em></Row>}
              {card.baseDurability != null && <Row label="Base Durability">{card.baseDurability}</Row>}
              {card.luckModifier != null && <Row label="Luck Modifier">{card.luckModifier}</Row>}
              {card.volatileBonus != null && <Row label="Volatile Bonus">{card.volatileBonus ? 'Yes' : 'No'}</Row>}
              {card.enemyFaction && <Row label="Enemy Faction">{card.enemyFaction}</Row>}
            </dl>
          </CardContent>
        </UICard>
      )}

      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Card</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete "{card.name}"? This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDeleteDialog(false)}>Cancel</Button>
            <Button variant="destructive" disabled={isDeleting} onClick={handleDelete}>
              {isDeleting ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
