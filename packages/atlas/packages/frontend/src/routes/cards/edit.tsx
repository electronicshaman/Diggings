import { useParams, useNavigate, Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { useCard } from '@/hooks/useCards'
import { useUpdateCard } from '@/hooks/useCardMutations'
import { CardForm } from '@/components/forms/CardForm'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'

export function CardEditPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: card, isLoading, error } = useCard(id)
  const { mutateAsync, isPending } = useUpdateCard()

  if (isLoading) {
    return (
      <div className="space-y-4 max-w-3xl mx-auto">
        <Skeleton className="h-10 w-48" />
        <Skeleton className="h-96 w-full" />
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

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link to={`/cards/${card.id}`}><ArrowLeft className="size-4" /></Link>
        </Button>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Edit Card</h1>
          <p className="text-muted-foreground font-mono text-sm">{card.id}</p>
        </div>
      </div>
      <CardForm
        isEdit
        submitLabel="Save Changes"
        isSubmitting={isPending}
        defaultValues={{
          ...card,
          id: card.id,
        }}
        onCancel={() => navigate(`/cards/${card.id}`)}
        onSubmit={async (data) => {
          await mutateAsync({ cardId: card.id, data: { ...data, id: card.id } })
          navigate(`/cards/${card.id}`)
        }}
      />
    </div>
  )
}
