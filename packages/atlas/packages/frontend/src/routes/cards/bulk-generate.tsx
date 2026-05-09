import { useState } from 'react'
import { Link } from 'react-router-dom'
import { CheckCircle2, XCircle, Loader2, ArrowLeft } from 'lucide-react'
import { CARD_OWNERS } from '@atlas/shared'
import { useBulkCardGenerate } from '@/hooks/useBulkCardGenerate'
import { CardDistributionChart } from '@/components/cards/CardDistributionChart'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

export default function BulkGeneratePage() {
  const [targetTotal, setTargetTotal] = useState(50)
  const [cardOwner, setCardOwner] = useState<string | undefined>(undefined)

  const { state, start, cancel, reset } = useBulkCardGenerate()

  const isRunning = state.status === 'running'
  const isDone = state.status === 'completed' || state.status === 'error'

  function handleStart() {
    start({ targetTotal, cardOwner })
  }

  const progress =
    state.totalCards > 0
      ? Math.round(((state.completed.length + state.failed.length) / state.totalCards) * 100)
      : 0

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="sm" asChild>
          <Link to="/cards">
            <ArrowLeft className="size-4" />
            Cards
          </Link>
        </Button>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Bulk Card Generation</h1>
          <p className="text-muted-foreground">
            Generate cards to fill distribution gaps via LLM
          </p>
        </div>
      </div>

      {/* Configuration */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Configuration</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-wrap gap-6">
            <div className="space-y-1.5">
              <Label htmlFor="target-total">Target Total Cards</Label>
              <Input
                id="target-total"
                type="number"
                min={1}
                max={200}
                value={targetTotal}
                onChange={(e) => setTargetTotal(Math.max(1, Math.min(200, Number(e.target.value))))}
                className="w-32"
                disabled={isRunning}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Owner Filter</Label>
              <Select
                value={cardOwner ?? 'all'}
                onValueChange={(v) => setCardOwner(v === 'all' ? undefined : v)}
                disabled={isRunning}
              >
                <SelectTrigger className="w-40">
                  <SelectValue placeholder="All owners" />
                </SelectTrigger>
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
      </Card>

      {/* Distribution gap chart */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Distribution Gaps</CardTitle>
        </CardHeader>
        <CardContent>
          <CardDistributionChart targetTotal={targetTotal} cardOwner={cardOwner} />
        </CardContent>
      </Card>

      {/* Action buttons */}
      {!isRunning && !isDone && (
        <Button onClick={handleStart} disabled={isRunning}>
          Start Generation
        </Button>
      )}

      {isDone && (
        <Button variant="outline" onClick={reset}>
          Reset
        </Button>
      )}

      {/* Progress */}
      {(isRunning || isDone) && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              {isRunning && <Loader2 className="size-4 animate-spin" />}
              {state.status === 'completed' && <CheckCircle2 className="size-4 text-green-500" />}
              {state.status === 'error' && <XCircle className="size-4 text-destructive" />}
              Progress
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1">
              <div className="flex justify-between text-sm">
                <span>
                  {state.completed.length + state.failed.length} / {state.totalCards} cards
                </span>
                <span>{progress}%</span>
              </div>
              <div className="h-2 bg-muted rounded-full overflow-hidden">
                <div
                  className="h-full bg-primary transition-all duration-300"
                  style={{ width: `${progress}%` }}
                />
              </div>
            </div>

            {state.status === 'error' && state.errorMessage && (
              <p className="text-sm text-destructive">{state.errorMessage}</p>
            )}

            {state.status === 'completed' && (
              <div className="flex gap-4 text-sm">
                <span className="text-green-600 dark:text-green-400">
                  {state.completed.length} generated
                </span>
                {state.failed.length > 0 && (
                  <span className="text-destructive">{state.failed.length} failed</span>
                )}
              </div>
            )}

            {isRunning && (
              <Button variant="outline" size="sm" onClick={cancel}>
                Cancel
              </Button>
            )}

            {/* Completed cards list */}
            {state.completed.length > 0 && (
              <div className="space-y-2">
                <p className="text-sm font-medium">Generated Cards</p>
                <div className="space-y-1.5 max-h-64 overflow-y-auto">
                  {state.completed.map((card) => (
                    <div
                      key={card.cardId}
                      className="flex items-center justify-between rounded-md border px-3 py-1.5 text-sm"
                    >
                      <Link
                        to={`/cards/${card.cardId}`}
                        className="font-medium hover:underline"
                      >
                        {card.name}
                      </Link>
                      <div className="flex gap-1.5">
                        <Badge variant="secondary">{card.cardType}</Badge>
                        <Badge variant="outline">{card.rarity}</Badge>
                        <span className="text-xs text-muted-foreground">{card.cardId}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Failed cards list */}
            {state.failed.length > 0 && (
              <div className="space-y-2">
                <p className="text-sm font-medium text-destructive">Failed Cards</p>
                <div className="space-y-1.5 max-h-40 overflow-y-auto">
                  {state.failed.map((failure, i) => (
                    <div
                      key={i}
                      className="rounded-md border border-destructive/30 bg-destructive/5 px-3 py-1.5 text-sm"
                    >
                      <span className="font-medium">
                        {failure.cardType} / {failure.rarity}
                      </span>
                      <span className="ml-2 text-muted-foreground">{failure.error}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {state.status === 'completed' && (
              <Button asChild variant="outline" size="sm">
                <Link to="/cards">View All Cards</Link>
              </Button>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  )
}
