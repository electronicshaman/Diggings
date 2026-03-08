import { useNavigate } from 'react-router-dom'
import { CardForm } from '@/components/forms/CardForm'
import { useCreateCard } from '@/hooks/useCardMutations'

export function CardCreatePage() {
  const navigate = useNavigate()
  const { mutateAsync, isPending } = useCreateCard()

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Create Card</h1>
        <p className="text-muted-foreground">Define a new forge card</p>
      </div>
      <CardForm
        submitLabel="Create Card"
        isSubmitting={isPending}
        onCancel={() => navigate('/cards')}
        onSubmit={async (data) => {
          const newCard = await mutateAsync(data)
          navigate(`/cards/${newCard.id}`)
        }}
      />
    </div>
  )
}
