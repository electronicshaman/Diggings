import { useState } from 'react';
import { Plus, Trash2, WrapText } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useFormStore } from '@/store/form-store';
import {
  ALL_BIOMES,
  BiomeDisplayNames,
  ALL_ACTS,
  ActNames,
  type BoolExpr,
  type Condition,
} from '@node-gen-web/shared';

type ConditionKind =
  | 'flag'
  | 'resource'
  | 'tag'
  | 'biome'
  | 'act'
  | 'difficulty'
  | 'cooldown'
  | 'seen';

const CONDITION_KINDS: { value: ConditionKind; label: string }[] = [
  { value: 'flag', label: 'Flag' },
  { value: 'resource', label: 'Resource' },
  { value: 'tag', label: 'Tag' },
  { value: 'biome', label: 'Biome' },
  { value: 'act', label: 'Act' },
  { value: 'difficulty', label: 'Difficulty' },
  { value: 'cooldown', label: 'Cooldown' },
  { value: 'seen', label: 'Seen' },
];

const RESOURCE_KEYS = ['health', 'sanity', 'gold', 'food', 'ammo'] as const;
const TAG_SCOPES = ['player', 'run', 'biome', 'world'] as const;

function isCondition(expr: BoolExpr): expr is Condition {
  return 'kind' in expr;
}

function isWrapper(
  expr: BoolExpr
): expr is { allOf: BoolExpr[] } | { anyOf: BoolExpr[] } | { noneOf: BoolExpr[] } {
  return 'allOf' in expr || 'anyOf' in expr || 'noneOf' in expr;
}

function getWrapperType(expr: BoolExpr): 'allOf' | 'anyOf' | 'noneOf' | null {
  if ('allOf' in expr) return 'allOf';
  if ('anyOf' in expr) return 'anyOf';
  if ('noneOf' in expr) return 'noneOf';
  return null;
}

function getWrapperChildren(expr: BoolExpr): BoolExpr[] {
  if ('allOf' in expr) return expr.allOf;
  if ('anyOf' in expr) return expr.anyOf;
  if ('noneOf' in expr) return expr.noneOf;
  return [];
}

function ConditionDisplay({ condition }: { condition: Condition }) {
  switch (condition.kind) {
    case 'flag':
      return (
        <span>
          Flag <code>{condition.key}</code> {condition.op} {String(condition.value)}
        </span>
      );
    case 'resource':
      return (
        <span>
          Resource <code>{condition.key}</code> {condition.op} {String(condition.value)}
        </span>
      );
    case 'tag':
      return (
        <span>
          Tag ({condition.scope}) {condition.op} <code>{condition.value}</code>
        </span>
      );
    case 'biome':
      return (
        <span>
          Biome {condition.op} {Array.isArray(condition.value) ? condition.value.join(', ') : condition.value}
        </span>
      );
    case 'act':
      return (
        <span>
          Act {condition.op} {Array.isArray(condition.value) ? condition.value.join(', ') : condition.value}
        </span>
      );
    case 'difficulty':
      return (
        <span>
          Difficulty {condition.op} {condition.value}
        </span>
      );
    case 'cooldown':
      return (
        <span>
          Cooldown <code>{condition.key}</code> {condition.op} {condition.value}
        </span>
      );
    case 'seen':
      return (
        <span>
          Seen <code>{condition.key}</code> {condition.op} {condition.value}
        </span>
      );
    default:
      return <span>Unknown condition</span>;
  }
}

function ExpressionTree({
  expr,
  path,
  onRemove,
  onWrap,
}: {
  expr: BoolExpr;
  path: number[];
  onRemove: (path: number[]) => void;
  onWrap: (path: number[], type: 'allOf' | 'anyOf' | 'noneOf') => void;
}) {
  if (isCondition(expr)) {
    return (
      <div className="flex items-center gap-2 rounded border bg-muted/50 p-2">
        <ConditionDisplay condition={expr} />
        <div className="ml-auto flex gap-1">
          <Button
            size="icon"
            variant="ghost"
            className="size-6"
            onClick={() => onRemove(path)}
          >
            <Trash2 className="size-3" />
          </Button>
        </div>
      </div>
    );
  }

  const wrapperType = getWrapperType(expr);
  const children = getWrapperChildren(expr);

  if (!wrapperType) return null;

  return (
    <Card className="border-l-4 border-l-primary/50">
      <CardContent className="p-3 space-y-2">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-primary">
            {wrapperType === 'allOf' && 'ALL OF'}
            {wrapperType === 'anyOf' && 'ANY OF'}
            {wrapperType === 'noneOf' && 'NONE OF'}
          </span>
          <Button
            size="icon"
            variant="ghost"
            className="ml-auto size-6"
            onClick={() => onRemove(path)}
          >
            <Trash2 className="size-3" />
          </Button>
        </div>
        <div className="space-y-2 pl-2">
          {children.map((child, index) => (
            <ExpressionTree
              key={index}
              expr={child}
              path={[...path, index]}
              onRemove={onRemove}
              onWrap={onWrap}
            />
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

function AddConditionDialog({
  open,
  onOpenChange,
  onAdd,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAdd: (condition: Condition) => void;
}) {
  const [kind, setKind] = useState<ConditionKind>('flag');
  const [flagKey, setFlagKey] = useState('');
  const [flagOp, setFlagOp] = useState<'==' | '!='>('==');
  const [flagValue, setFlagValue] = useState(true);
  const [resourceKey, setResourceKey] = useState<string>('health');
  const [resourceOp, setResourceOp] = useState<'>=' | '<=' | '=='>('>=');
  const [resourceValue, setResourceValue] = useState(0);
  const [tagScope, setTagScope] = useState<'player' | 'run' | 'biome' | 'world'>('player');
  const [tagOp, setTagOp] = useState<'contains' | 'not_contains'>('contains');
  const [tagValue, setTagValue] = useState('');
  const [biomeOp, setBiomeOp] = useState<'==' | 'in'>('==');
  const [biomeValue, setBiomeValue] = useState<string[]>([]);
  const [actOp, setActOp] = useState<'==' | 'in' | '>='>('==');
  const [actValue, setActValue] = useState<number[]>([]);
  const [difficultyOp, setDifficultyOp] = useState<'>=' | '<='>('>=');
  const [difficultyValue, setDifficultyValue] = useState(1);
  const [cooldownKey, setCooldownKey] = useState('');
  const [cooldownOp, setCooldownOp] = useState<'>=' | '<='>('>=');
  const [cooldownValue, setCooldownValue] = useState(0);
  const [seenKey, setSeenKey] = useState('');
  const [seenOp, setSeenOp] = useState<'==' | '!=' | '>=' | '<='>('>=');
  const [seenValue, setSeenValue] = useState(0);

  const handleAdd = () => {
    let condition: Condition;

    switch (kind) {
      case 'flag':
        condition = { kind: 'flag', key: flagKey, op: flagOp, value: flagValue };
        break;
      case 'resource':
        condition = { kind: 'resource', key: resourceKey, op: resourceOp, value: resourceValue };
        break;
      case 'tag':
        condition = { kind: 'tag', scope: tagScope, op: tagOp, value: tagValue };
        break;
      case 'biome':
        condition = {
          kind: 'biome',
          op: biomeOp,
          value: biomeOp === '==' ? biomeValue[0] : biomeValue,
        };
        break;
      case 'act':
        condition = {
          kind: 'act',
          op: actOp,
          value: actOp === '==' || actOp === '>=' ? actValue[0] : actValue,
        };
        break;
      case 'difficulty':
        condition = { kind: 'difficulty', op: difficultyOp, value: difficultyValue };
        break;
      case 'cooldown':
        condition = { kind: 'cooldown', key: cooldownKey, op: cooldownOp, value: cooldownValue };
        break;
      case 'seen':
        condition = { kind: 'seen', key: seenKey, op: seenOp, value: seenValue };
        break;
      default:
        return;
    }

    onAdd(condition);
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add Condition</DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Condition Type</Label>
            <Select value={kind} onValueChange={(v) => setKind(v as ConditionKind)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {CONDITION_KINDS.map((k) => (
                  <SelectItem key={k.value} value={k.value}>
                    {k.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {kind === 'flag' && (
            <>
              <div className="space-y-2">
                <Label>Flag Key</Label>
                <Input
                  value={flagKey}
                  onChange={(e) => setFlagKey(e.target.value)}
                  placeholder="e.g., met_publican"
                />
              </div>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select value={flagOp} onValueChange={(v) => setFlagOp(v as '==' | '!=')}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="==">equals (==)</SelectItem>
                    <SelectItem value="!=">not equals (!=)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="flex items-center gap-2">
                <Switch checked={flagValue} onCheckedChange={setFlagValue} />
                <Label>{flagValue ? 'true' : 'false'}</Label>
              </div>
            </>
          )}

          {kind === 'resource' && (
            <>
              <div className="space-y-2">
                <Label>Resource</Label>
                <Select value={resourceKey} onValueChange={setResourceKey}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {RESOURCE_KEYS.map((r) => (
                      <SelectItem key={r} value={r}>
                        {r.charAt(0).toUpperCase() + r.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select
                  value={resourceOp}
                  onValueChange={(v) => setResourceOp(v as '>=' | '<=' | '==')}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value=">=">greater or equal (&gt;=)</SelectItem>
                    <SelectItem value="<=">less or equal (&lt;=)</SelectItem>
                    <SelectItem value="==">equals (==)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Value</Label>
                <Input
                  type="number"
                  value={resourceValue}
                  onChange={(e) => setResourceValue(Number(e.target.value))}
                />
              </div>
            </>
          )}

          {kind === 'tag' && (
            <>
              <div className="space-y-2">
                <Label>Scope</Label>
                <Select value={tagScope} onValueChange={(v) => setTagScope(v as typeof tagScope)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {TAG_SCOPES.map((s) => (
                      <SelectItem key={s} value={s}>
                        {s.charAt(0).toUpperCase() + s.slice(1)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select
                  value={tagOp}
                  onValueChange={(v) => setTagOp(v as 'contains' | 'not_contains')}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="contains">contains</SelectItem>
                    <SelectItem value="not_contains">not contains</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Tag Value</Label>
                <Input
                  value={tagValue}
                  onChange={(e) => setTagValue(e.target.value)}
                  placeholder="e.g., tainted"
                />
              </div>
            </>
          )}

          {kind === 'biome' && (
            <>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select value={biomeOp} onValueChange={(v) => setBiomeOp(v as '==' | 'in')}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="==">equals (==)</SelectItem>
                    <SelectItem value="in">in list (in)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Biome(s)</Label>
                <div className="grid grid-cols-2 gap-2">
                  {ALL_BIOMES.map((b) => (
                    <label key={b} className="flex items-center gap-2 cursor-pointer">
                      <input
                        type={biomeOp === '==' ? 'radio' : 'checkbox'}
                        name="biome-select"
                        checked={biomeValue.includes(b)}
                        onChange={(e) => {
                          if (biomeOp === '==') {
                            setBiomeValue([b]);
                          } else if (e.target.checked) {
                            setBiomeValue([...biomeValue, b]);
                          } else {
                            setBiomeValue(biomeValue.filter((v) => v !== b));
                          }
                        }}
                        className="size-4"
                      />
                      <span className="text-sm">{BiomeDisplayNames[b]}</span>
                    </label>
                  ))}
                </div>
              </div>
            </>
          )}

          {kind === 'act' && (
            <>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select value={actOp} onValueChange={(v) => setActOp(v as '==' | 'in' | '>=')}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="==">equals (==)</SelectItem>
                    <SelectItem value="in">in list (in)</SelectItem>
                    <SelectItem value=">=">greater or equal (&gt;=)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Act(s)</Label>
                <div className="flex flex-wrap gap-4">
                  {ALL_ACTS.map((a) => (
                    <label key={a} className="flex items-center gap-2 cursor-pointer">
                      <input
                        type={actOp === 'in' ? 'checkbox' : 'radio'}
                        name="act-select"
                        checked={actValue.includes(a)}
                        onChange={(e) => {
                          if (actOp === 'in') {
                            if (e.target.checked) {
                              setActValue([...actValue, a]);
                            } else {
                              setActValue(actValue.filter((v) => v !== a));
                            }
                          } else {
                            setActValue([a]);
                          }
                        }}
                        className="size-4"
                      />
                      <span className="text-sm">
                        {a}: {ActNames[a]}
                      </span>
                    </label>
                  ))}
                </div>
              </div>
            </>
          )}

          {kind === 'difficulty' && (
            <>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select
                  value={difficultyOp}
                  onValueChange={(v) => setDifficultyOp(v as '>=' | '<=')}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value=">=">greater or equal (&gt;=)</SelectItem>
                    <SelectItem value="<=">less or equal (&lt;=)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Difficulty Value</Label>
                <Input
                  type="number"
                  value={difficultyValue}
                  onChange={(e) => setDifficultyValue(Number(e.target.value))}
                />
              </div>
            </>
          )}

          {kind === 'cooldown' && (
            <>
              <div className="space-y-2">
                <Label>Cooldown Key</Label>
                <Input
                  value={cooldownKey}
                  onChange={(e) => setCooldownKey(e.target.value)}
                  placeholder="e.g., combat"
                />
              </div>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select
                  value={cooldownOp}
                  onValueChange={(v) => setCooldownOp(v as '>=' | '<=')}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value=">=">greater or equal (&gt;=)</SelectItem>
                    <SelectItem value="<=">less or equal (&lt;=)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Steps Since</Label>
                <Input
                  type="number"
                  value={cooldownValue}
                  onChange={(e) => setCooldownValue(Number(e.target.value))}
                />
              </div>
            </>
          )}

          {kind === 'seen' && (
            <>
              <div className="space-y-2">
                <Label>Seen Key</Label>
                <Input
                  value={seenKey}
                  onChange={(e) => setSeenKey(e.target.value)}
                  placeholder="e.g., node_id or beat_id"
                />
              </div>
              <div className="space-y-2">
                <Label>Operator</Label>
                <Select value={seenOp} onValueChange={(v) => setSeenOp(v as typeof seenOp)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="==">equals (==)</SelectItem>
                    <SelectItem value="!=">not equals (!=)</SelectItem>
                    <SelectItem value=">=">greater or equal (&gt;=)</SelectItem>
                    <SelectItem value="<=">less or equal (&lt;=)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Times Seen</Label>
                <Input
                  type="number"
                  value={seenValue}
                  onChange={(e) => setSeenValue(Number(e.target.value))}
                />
              </div>
            </>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleAdd}>Add Condition</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export function EligibilityBuilder() {
  const { formData, setFormData, nextStep, prevStep } = useFormStore();
  const [dialogOpen, setDialogOpen] = useState(false);

  const eligibility = formData.eligibility;
  const currentExpr = eligibility?.when;

  const handleAddCondition = (condition: Condition) => {
    if (!currentExpr) {
      setFormData({
        eligibility: {
          when: condition,
        },
      });
    } else if (isWrapper(currentExpr)) {
      const wrapperType = getWrapperType(currentExpr)!;
      const children = getWrapperChildren(currentExpr);
      setFormData({
        eligibility: {
          ...eligibility,
          when: { [wrapperType]: [...children, condition] } as BoolExpr,
        },
      });
    } else {
      setFormData({
        eligibility: {
          ...eligibility,
          when: { allOf: [currentExpr, condition] },
        },
      });
    }
  };

  const handleRemove = (path: number[]) => {
    if (path.length === 0) {
      setFormData({
        eligibility: undefined,
      });
      return;
    }

    const removeAtPath = (expr: BoolExpr, pathIndex: number): BoolExpr | null => {
      if (pathIndex >= path.length) return null;

      if (!isWrapper(expr)) return expr;

      const wrapperType = getWrapperType(expr)!;
      const children = [...getWrapperChildren(expr)];

      if (pathIndex === path.length - 1) {
        children.splice(path[pathIndex], 1);
        if (children.length === 0) return null;
        if (children.length === 1) return children[0];
        return { [wrapperType]: children } as BoolExpr;
      }

      const result = removeAtPath(children[path[pathIndex]], pathIndex + 1);
      if (result === null) {
        children.splice(path[pathIndex], 1);
      } else {
        children[path[pathIndex]] = result;
      }

      if (children.length === 0) return null;
      if (children.length === 1) return children[0];
      return { [wrapperType]: children } as BoolExpr;
    };

    const result = removeAtPath(currentExpr!, 0);
    setFormData({
      eligibility: result ? { ...eligibility, when: result } : undefined,
    });
  };

  const handleWrap = (_path: number[], _type: 'allOf' | 'anyOf' | 'noneOf') => {
    // This would wrap selected items - simplified for v1
  };

  const wrapAll = (type: 'allOf' | 'anyOf' | 'noneOf') => {
    if (!currentExpr) return;

    if (isWrapper(currentExpr)) {
      const children = getWrapperChildren(currentExpr);
      setFormData({
        eligibility: {
          ...eligibility,
          when: { [type]: children } as BoolExpr,
        },
      });
    } else {
      setFormData({
        eligibility: {
          ...eligibility,
          when: { [type]: [currentExpr] } as BoolExpr,
        },
      });
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold">Eligibility Conditions</h2>
        <p className="text-sm text-muted-foreground">
          Configure when this node can appear (optional)
        </p>
      </div>

      <div className="space-y-4">
        {currentExpr ? (
          <ExpressionTree
            expr={currentExpr}
            path={[]}
            onRemove={handleRemove}
            onWrap={handleWrap}
          />
        ) : (
          <div className="rounded-lg border border-dashed p-8 text-center text-muted-foreground">
            No eligibility conditions set. Node will always be eligible.
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setDialogOpen(true)}>
            <Plus className="mr-2 size-4" />
            Add Condition
          </Button>

          {currentExpr && (
            <>
              <Button variant="outline" onClick={() => wrapAll('allOf')}>
                <WrapText className="mr-2 size-4" />
                Wrap All Of
              </Button>
              <Button variant="outline" onClick={() => wrapAll('anyOf')}>
                <WrapText className="mr-2 size-4" />
                Wrap Any Of
              </Button>
              <Button variant="outline" onClick={() => wrapAll('noneOf')}>
                <WrapText className="mr-2 size-4" />
                Wrap None Of
              </Button>
            </>
          )}
        </div>
      </div>

      <AddConditionDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onAdd={handleAddCondition}
      />

      <div className="flex justify-between pt-4">
        <Button variant="outline" onClick={prevStep}>
          Back
        </Button>
        <Button onClick={nextStep}>Next</Button>
      </div>
    </div>
  );
}
