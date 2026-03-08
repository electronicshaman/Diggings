import { useForm, useFieldArray, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { CardSchema } from '@atlas/shared'
import { CARD_TYPES, CARD_RARITIES, CARD_OWNERS, CARD_HANDLING, ACCESSIBILITY_TIERS } from '@atlas/shared'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import { Card as UICard, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Plus, Trash2 } from 'lucide-react'
import { z } from 'zod'

const FormSchema = CardSchema.extend({
  id: z.string().optional(),
})
type FormValues = z.infer<typeof FormSchema>

interface CardFormProps {
  defaultValues?: Partial<FormValues>
  onSubmit: (data: FormValues) => void | Promise<void>
  isSubmitting?: boolean
  submitLabel?: string
  onCancel?: () => void
  isEdit?: boolean
}

export function CardForm({
  defaultValues,
  onSubmit,
  isSubmitting,
  submitLabel = 'Save',
  onCancel,
  isEdit,
}: CardFormProps) {
  const form = useForm<FormValues>({
    resolver: zodResolver(FormSchema),
    defaultValues: {
      id: '',
      name: '',
      description: '',
      cardType: 'Attack',
      rarity: 'Common',
      cardOwner: 'PLAYER',
      handling: 'Standard',
      accessibilityTier: 'Starting',
      costs: [],
      effects: [],
      classAffinity: [],
      ...defaultValues,
    },
  })

  const { fields: costFields, append: appendCost, remove: removeCost } = useFieldArray({
    control: form.control,
    name: 'costs',
  })

  const { fields: effectFields, append: appendEffect, remove: removeEffect } = useFieldArray({
    control: form.control,
    name: 'effects',
  })

  const handleSubmit = form.handleSubmit(async (data) => {
    await onSubmit(data)
  })

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Identity */}
      <UICard>
        <CardHeader>
          <CardTitle>Identity</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="id">ID</Label>
            <Input
              id="id"
              placeholder="CARD_001 (auto-generated if blank)"
              disabled={isEdit}
              {...form.register('id')}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="name">Name *</Label>
            <Input id="name" placeholder="Card name" {...form.register('name')} />
            {form.formState.errors.name && (
              <p className="text-sm text-destructive">{form.formState.errors.name.message}</p>
            )}
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="description">Description</Label>
            <Textarea id="description" rows={3} {...form.register('description')} />
          </div>
        </CardContent>
      </UICard>

      {/* Classification */}
      <UICard>
        <CardHeader>
          <CardTitle>Classification</CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4 md:grid-cols-3">
          <div className="space-y-1.5">
            <Label>Card Type *</Label>
            <Controller
              control={form.control}
              name="cardType"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {CARD_TYPES.map((t) => (
                      <SelectItem key={t} value={t}>{t}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Rarity *</Label>
            <Controller
              control={form.control}
              name="rarity"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {CARD_RARITIES.map((r) => (
                      <SelectItem key={r} value={r}>{r}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Owner *</Label>
            <Controller
              control={form.control}
              name="cardOwner"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {CARD_OWNERS.map((o) => (
                      <SelectItem key={o} value={o}>{o}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Handling *</Label>
            <Controller
              control={form.control}
              name="handling"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {CARD_HANDLING.map((h) => (
                      <SelectItem key={h} value={h}>{h}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Accessibility Tier *</Label>
            <Controller
              control={form.control}
              name="accessibilityTier"
              render={({ field }) => (
                <Select value={field.value} onValueChange={field.onChange}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {ACCESSIBILITY_TIERS.map((a) => (
                      <SelectItem key={a} value={a}>{a}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
          </div>
        </CardContent>
      </UICard>

      {/* Costs */}
      <UICard>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Costs</CardTitle>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => appendCost({ type: 'energy', amount: 1 })}
            >
              <Plus className="size-4 mr-1" />
              Add Cost
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {costFields.length === 0 && (
            <p className="text-sm text-muted-foreground">No costs. Card is free to play.</p>
          )}
          {costFields.map((field, idx) => {
            const costType = form.watch(`costs.${idx}.type`)
            return (
              <div key={field.id} className="flex items-end gap-3">
                <div className="space-y-1.5 w-32">
                  <Label>Type</Label>
                  <Controller
                    control={form.control}
                    name={`costs.${idx}.type`}
                    render={({ field: f }) => (
                      <Select value={f.value} onValueChange={f.onChange}>
                        <SelectTrigger><SelectValue /></SelectTrigger>
                        <SelectContent>
                          <SelectItem value="energy">Energy</SelectItem>
                          <SelectItem value="sanity">Sanity</SelectItem>
                          <SelectItem value="resource">Resource</SelectItem>
                        </SelectContent>
                      </Select>
                    )}
                  />
                </div>
                <div className="space-y-1.5 w-20">
                  <Label>Amount</Label>
                  <Input
                    type="number"
                    min={0}
                    {...form.register(`costs.${idx}.amount`, { valueAsNumber: true })}
                  />
                </div>
                {costType === 'resource' && (
                  <div className="space-y-1.5 flex-1">
                    <Label>Resource Key</Label>
                    <Input
                      placeholder="e.g. gold"
                      {...form.register(`costs.${idx}.resourceKey`)}
                    />
                  </div>
                )}
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  onClick={() => removeCost(idx)}
                >
                  <Trash2 className="size-4 text-destructive" />
                </Button>
              </div>
            )
          })}
        </CardContent>
      </UICard>

      {/* Effects */}
      <UICard>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Effects</CardTitle>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => appendEffect({ handlerId: '', params: {} })}
            >
              <Plus className="size-4 mr-1" />
              Add Effect
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {effectFields.length === 0 && (
            <p className="text-sm text-muted-foreground">No effects defined.</p>
          )}
          {effectFields.map((field, idx) => (
            <div key={field.id} className="flex items-start gap-3">
              <div className="space-y-1.5 w-48">
                <Label>Handler ID</Label>
                <Input
                  placeholder="e.g. deal_damage"
                  {...form.register(`effects.${idx}.handlerId`)}
                />
              </div>
              <div className="space-y-1.5 flex-1">
                <Label>Params (JSON)</Label>
                <Textarea
                  rows={2}
                  placeholder="{}"
                  defaultValue={JSON.stringify(field.params ?? {})}
                  onChange={(e) => {
                    try {
                      form.setValue(`effects.${idx}.params`, JSON.parse(e.target.value))
                    } catch {
                      // ignore invalid JSON while typing
                    }
                  }}
                />
              </div>
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="mt-6"
                onClick={() => removeEffect(idx)}
              >
                <Trash2 className="size-4 text-destructive" />
              </Button>
            </div>
          ))}
        </CardContent>
      </UICard>

      {/* Class Affinity */}
      <UICard>
        <CardHeader>
          <CardTitle>Class Affinity</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-1.5">
            <Label htmlFor="classAffinity">Classes (comma-separated)</Label>
            <Input
              id="classAffinity"
              placeholder="e.g. Outlaw, Dustwalker"
              defaultValue={(defaultValues?.classAffinity ?? []).join(', ')}
              onChange={(e) => {
                const val = e.target.value
                const arr = val.split(',').map((s) => s.trim()).filter(Boolean)
                form.setValue('classAffinity', arr)
              }}
            />
          </div>
        </CardContent>
      </UICard>

      {/* Optional Fields */}
      <UICard>
        <CardHeader>
          <CardTitle>Optional Fields</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="flavorText">Flavor Text</Label>
            <Textarea id="flavorText" rows={2} {...form.register('flavorText')} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="baseDurability">Base Durability</Label>
              <Input
                id="baseDurability"
                type="number"
                min={0}
                {...form.register('baseDurability', { setValueAs: (v) => (v === '' ? undefined : Number(v)) })}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="luckModifier">Luck Modifier</Label>
              <Input
                id="luckModifier"
                type="number"
                {...form.register('luckModifier', { setValueAs: (v) => (v === '' ? undefined : Number(v)) })}
              />
            </div>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="enemyFaction">Enemy Faction</Label>
            <Input id="enemyFaction" placeholder="e.g. Dust Cult" {...form.register('enemyFaction')} />
          </div>
          <div className="flex items-center gap-3">
            <Controller
              control={form.control}
              name="volatileBonus"
              render={({ field }) => (
                <Switch
                  id="volatileBonus"
                  checked={field.value ?? false}
                  onCheckedChange={field.onChange}
                />
              )}
            />
            <Label htmlFor="volatileBonus">Volatile Bonus</Label>
          </div>
        </CardContent>
      </UICard>

      {/* Actions */}
      <div className="flex justify-end gap-3">
        {onCancel && (
          <Button type="button" variant="outline" onClick={onCancel}>
            Cancel
          </Button>
        )}
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Saving...' : submitLabel}
        </Button>
      </div>
    </form>
  )
}
