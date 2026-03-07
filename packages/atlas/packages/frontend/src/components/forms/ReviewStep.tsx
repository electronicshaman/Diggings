import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useFormStore } from '@/store/form-store';
import { useCreateNode } from '@/hooks/useNodeMutations';
import {
  NodeTypeDisplayNames,
  BiomeDisplayNames,
  ActNames,
  NodeType,
  type AnyNodeMetadata,
  type BoolExpr,
  type Condition,
} from '@atlas/shared';

function isCondition(expr: BoolExpr): expr is Condition {
  return 'kind' in expr;
}

function renderExpr(expr: BoolExpr, depth = 0): React.ReactNode {
  const indent = { paddingLeft: `${depth * 16}px` };

  if (isCondition(expr)) {
    let display = '';
    switch (expr.kind) {
      case 'flag':
        display = `Flag "${expr.key}" ${expr.op} ${expr.value}`;
        break;
      case 'resource':
        display = `Resource "${expr.key}" ${expr.op} ${expr.value}`;
        break;
      case 'tag':
        display = `Tag (${expr.scope}) ${expr.op} "${expr.value}"`;
        break;
      case 'biome':
        display = `Biome ${expr.op} ${Array.isArray(expr.value) ? expr.value.join(', ') : expr.value}`;
        break;
      case 'act':
        display = `Act ${expr.op} ${Array.isArray(expr.value) ? expr.value.join(', ') : expr.value}`;
        break;
      case 'difficulty':
        display = `Difficulty ${expr.op} ${expr.value}`;
        break;
      case 'cooldown':
        display = `Cooldown "${expr.key}" ${expr.op} ${expr.value}`;
        break;
      case 'seen':
        display = `Seen "${expr.key}" ${expr.op} ${expr.value}`;
        break;
      default:
        display = 'Unknown condition';
    }
    return (
      <div style={indent} className="text-sm">
        • {display}
      </div>
    );
  }

  let wrapperType: string;
  let children: BoolExpr[];

  if ('allOf' in expr) {
    wrapperType = 'ALL OF';
    children = expr.allOf;
  } else if ('anyOf' in expr) {
    wrapperType = 'ANY OF';
    children = expr.anyOf;
  } else if ('noneOf' in expr) {
    wrapperType = 'NONE OF';
    children = expr.noneOf;
  } else {
    return null;
  }

  return (
    <div style={indent}>
      <div className="text-sm font-medium text-primary">{wrapperType}</div>
      {children.map((child, i) => (
        <div key={i}>{renderExpr(child, depth + 1)}</div>
      ))}
    </div>
  );
}

export function ReviewStep() {
  const { formData, prevStep, resetForm } = useFormStore();
  const navigate = useNavigate();
  const createNode = useCreateNode();

  const handleSubmit = async () => {
    try {
      const node = await createNode.mutateAsync(formData as Omit<AnyNodeMetadata, 'id'>);
      toast.success('Node created successfully');
      resetForm();
      navigate(`/nodes/${encodeURIComponent(node.id)}`);
    } catch {
      toast.error('Failed to create node');
    }
  };

  const typeName = formData.type ? NodeTypeDisplayNames[formData.type] : 'Unknown';
  const biomeName = formData.biome ? BiomeDisplayNames[formData.biome] : 'Not set';

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold">Review & Create</h2>
        <p className="text-sm text-muted-foreground">
          Review your node configuration before creating
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Base Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Name</span>
              <span className="font-medium">{formData.name || 'Not set'}</span>
            </div>
            {formData.id && (
              <div className="flex justify-between">
                <span className="text-muted-foreground">ID</span>
                <code className="text-xs">{formData.id}</code>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-muted-foreground">Type</span>
              <Badge variant="secondary">{typeName}</Badge>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Biome</span>
              <span>{biomeName}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Acts</span>
              <div className="flex gap-1">
                {formData.acts?.map((act) => (
                  <Badge key={act} variant="outline" className="text-xs">
                    {ActNames[act]}
                  </Badge>
                ))}
              </div>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Replaceable</span>
              <span>{formData.isReplaceable ? 'Yes' : 'No'}</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Tags & Themes</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            {formData.replacementTags && formData.replacementTags.length > 0 && (
              <div>
                <span className="text-muted-foreground">Replacement Tags</span>
                <div className="mt-1 flex flex-wrap gap-1">
                  {formData.replacementTags.map((tag) => (
                    <Badge key={tag} variant="outline" className="text-xs">
                      {tag}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {formData.themes && formData.themes.length > 0 && (
              <div>
                <span className="text-muted-foreground">Themes</span>
                <div className="mt-1 flex flex-wrap gap-1">
                  {formData.themes.map((theme) => (
                    <Badge key={theme} variant="outline" className="text-xs">
                      {theme}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {formData.entityTypes && formData.entityTypes.length > 0 && (
              <div>
                <span className="text-muted-foreground">Entity Types</span>
                <div className="mt-1 flex flex-wrap gap-1">
                  {formData.entityTypes.map((et) => (
                    <Badge key={et} variant="outline" className="text-xs">
                      {et}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {(!formData.replacementTags?.length &&
              !formData.themes?.length &&
              !formData.entityTypes?.length) && (
              <span className="text-muted-foreground">No tags configured</span>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">{typeName} Properties</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {formData.type === NodeType.Combat && (
              <>
                {'enemyTypeHooks' in formData && formData.enemyTypeHooks && formData.enemyTypeHooks.length > 0 && (
                  <div>
                    <span className="text-muted-foreground">Enemy Types</span>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {formData.enemyTypeHooks.map((et) => (
                        <Badge key={et} variant="secondary" className="text-xs">
                          {et}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                {'environmentalContext' in formData && formData.environmentalContext && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Environment</span>
                    <span>{formData.environmentalContext}</span>
                  </div>
                )}
                {'estimatedCombatDifficulty' in formData && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Difficulty</span>
                    <span>{formData.estimatedCombatDifficulty}/5</span>
                  </div>
                )}
              </>
            )}
            {formData.type === NodeType.Choice && (
              <>
                {'consequenceHooks' in formData && formData.consequenceHooks && formData.consequenceHooks.length > 0 && (
                  <div>
                    <span className="text-muted-foreground">Consequence Hooks</span>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {formData.consequenceHooks.map((ch) => (
                        <Badge key={ch} variant="secondary" className="text-xs">
                          {ch}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                {'dilemmaType' in formData && formData.dilemmaType && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Dilemma Type</span>
                    <span className="capitalize">{formData.dilemmaType}</span>
                  </div>
                )}
              </>
            )}
            {formData.type === NodeType.Trade && (
              <>
                {'traderArchetype' in formData && formData.traderArchetype && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Trader Archetype</span>
                    <span>{formData.traderArchetype}</span>
                  </div>
                )}
                {'pricingHooks' in formData && formData.pricingHooks && formData.pricingHooks.length > 0 && (
                  <div>
                    <span className="text-muted-foreground">Pricing Hooks</span>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {formData.pricingHooks.map((ph) => (
                        <Badge key={ph} variant="secondary" className="text-xs">
                          {ph}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
              </>
            )}
            {formData.type === NodeType.Rest && (
              <>
                {'restType' in formData && formData.restType && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Rest Type</span>
                    <span className="capitalize">{formData.restType}</span>
                  </div>
                )}
                {'interruptionChance' in formData && formData.interruptionChance && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Interruption Chance</span>
                    <span className="capitalize">{formData.interruptionChance}</span>
                  </div>
                )}
              </>
            )}
            {formData.type === NodeType.Passage && (
              <>
                {'travelEventHooks' in formData && formData.travelEventHooks && formData.travelEventHooks.length > 0 && (
                  <div>
                    <span className="text-muted-foreground">Travel Events</span>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {formData.travelEventHooks.map((te) => (
                        <Badge key={te} variant="secondary" className="text-xs">
                          {te}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                {'environmentalStorytelling' in formData && formData.environmentalStorytelling && (
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Storytelling</span>
                    <span>{formData.environmentalStorytelling}</span>
                  </div>
                )}
              </>
            )}
            {formData.type === NodeType.StateCheck && (
              <>
                {'conditionHooks' in formData && formData.conditionHooks && formData.conditionHooks.length > 0 && (
                  <div>
                    <span className="text-muted-foreground">Condition Hooks</span>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {formData.conditionHooks.map((ch) => (
                        <Badge key={ch} variant="secondary" className="text-xs">
                          {ch}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
              </>
            )}
            {formData.type === NodeType.Transition && (
              <>
                {'narrativeSummary' in formData && formData.narrativeSummary && (
                  <div>
                    <span className="text-muted-foreground">Narrative Summary</span>
                    <p className="mt-1 text-sm">{formData.narrativeSummary}</p>
                  </div>
                )}
                {'worldStateShifts' in formData && formData.worldStateShifts && formData.worldStateShifts.length > 0 && (
                  <div>
                    <span className="text-muted-foreground">World State Shifts</span>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {formData.worldStateShifts.map((ws) => (
                        <Badge key={ws} variant="secondary" className="text-xs">
                          {ws}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Eligibility</CardTitle>
          </CardHeader>
          <CardContent>
            {formData.eligibility?.when ? (
              renderExpr(formData.eligibility.when)
            ) : (
              <span className="text-sm text-muted-foreground">
                No conditions (always eligible)
              </span>
            )}
          </CardContent>
        </Card>
      </div>

      <Separator />

      <div className="flex justify-between pt-4">
        <Button variant="outline" onClick={prevStep}>
          Back
        </Button>
        <Button onClick={handleSubmit} disabled={createNode.isPending}>
          {createNode.isPending ? 'Creating...' : 'Create Node'}
        </Button>
      </div>
    </div>
  );
}
