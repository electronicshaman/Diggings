import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useForm, FormProvider } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { ArrowLeft, Sparkles } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { useFormStore } from '@/store/form-store';
import { NodeTypeSelect } from '@/components/forms/NodeTypeSelect';
import { BaseNodeForm } from '@/components/forms/BaseNodeForm';
import {
  CombatForm,
  ChoiceForm,
  TradeForm,
  RestForm,
  PassageForm,
  StateCheckForm,
  TransitionForm,
  EligibilityBuilder,
  ReviewStep,
} from '@/components/forms';
import { NodeType, NodeTypeDisplayNames, type AnyNodeMetadata } from '@atlas/shared';
import { Button } from '@/components/ui/button';

const STEP_LABELS = [
  'Select Type',
  'Base Fields',
  'Type-Specific',
  'Eligibility',
  'Review',
];

const typeSpecificSchema = z.object({
  enemyTypeHooks: z.array(z.string()).optional(),
  environmentalContext: z.string().optional(),
  estimatedCombatDifficulty: z.number().min(1).max(5).optional(),
  consequenceHooks: z.array(z.string()).optional(),
  dilemmaType: z.enum(['moral', 'practical', 'survival']).optional(),
  traderArchetype: z.string().optional(),
  pricingHooks: z.array(z.string()).optional(),
  restType: z.enum(['safe', 'risky', 'sacred']).optional(),
  interruptionChance: z.enum(['none', 'low', 'medium', 'high']).optional(),
  dreamHooks: z.array(z.string()).optional(),
  travelEventHooks: z.array(z.string()).optional(),
  environmentalStorytelling: z.string().optional(),
  resourceCost: z.object({
    type: z.string(),
    amount: z.number(),
    optional: z.boolean().optional(),
  }).optional(),
  conditionHooks: z.array(z.string()).optional(),
  branchTargets: z.object({
    success: z.string(),
    failure: z.string(),
  }).optional(),
  actChangeTrigger: z.number().optional(),
  narrativeSummary: z.string().optional(),
  worldStateShifts: z.array(z.string()).optional(),
});

type TypeSpecificFormData = z.infer<typeof typeSpecificSchema>;

function StepIndicator({ currentStep }: { currentStep: number }) {
  return (
    <div className="flex items-center gap-2">
      {STEP_LABELS.map((label, index) => (
        <div key={label} className="flex items-center gap-2">
          <div
            className={`flex size-8 items-center justify-center rounded-full text-sm font-medium ${
              index === currentStep
                ? 'bg-primary text-primary-foreground'
                : index < currentStep
                  ? 'bg-primary/20 text-primary'
                  : 'bg-muted text-muted-foreground'
            }`}
          >
            {index + 1}
          </div>
          <span
            className={`hidden text-sm sm:inline ${
              index === currentStep
                ? 'font-medium'
                : 'text-muted-foreground'
            }`}
          >
            {label}
          </span>
          {index < STEP_LABELS.length - 1 && (
            <Separator className="hidden w-8 sm:block" />
          )}
        </div>
      ))}
    </div>
  );
}

function TypeSpecificStep() {
  const { formData, setFormData, nextStep, prevStep } = useFormStore();
  const typeName = formData.type ? NodeTypeDisplayNames[formData.type] : 'Unknown';

  const methods = useForm<TypeSpecificFormData>({
    resolver: zodResolver(typeSpecificSchema),
    defaultValues: {
      enemyTypeHooks: 'enemyTypeHooks' in formData ? formData.enemyTypeHooks : [],
      environmentalContext: 'environmentalContext' in formData ? formData.environmentalContext : '',
      estimatedCombatDifficulty: 'estimatedCombatDifficulty' in formData ? formData.estimatedCombatDifficulty : 1,
      consequenceHooks: 'consequenceHooks' in formData ? formData.consequenceHooks : [],
      dilemmaType: 'dilemmaType' in formData ? formData.dilemmaType : undefined,
      traderArchetype: 'traderArchetype' in formData ? formData.traderArchetype : '',
      pricingHooks: 'pricingHooks' in formData ? formData.pricingHooks : [],
      restType: 'restType' in formData ? formData.restType : undefined,
      interruptionChance: 'interruptionChance' in formData ? formData.interruptionChance : undefined,
      dreamHooks: 'dreamHooks' in formData ? formData.dreamHooks : [],
      travelEventHooks: 'travelEventHooks' in formData ? formData.travelEventHooks : [],
      environmentalStorytelling: 'environmentalStorytelling' in formData ? formData.environmentalStorytelling : '',
      resourceCost: 'resourceCost' in formData ? formData.resourceCost : undefined,
      conditionHooks: 'conditionHooks' in formData ? formData.conditionHooks : [],
      branchTargets: 'branchTargets' in formData ? formData.branchTargets : undefined,
      actChangeTrigger: 'actChangeTrigger' in formData ? formData.actChangeTrigger : undefined,
      narrativeSummary: 'narrativeSummary' in formData ? formData.narrativeSummary : '',
      worldStateShifts: 'worldStateShifts' in formData ? formData.worldStateShifts : [],
    },
  });

  const onSubmit = (data: TypeSpecificFormData) => {
    const typeData: Partial<AnyNodeMetadata> = {};

    switch (formData.type) {
      case NodeType.Combat:
        Object.assign(typeData, {
          enemyTypeHooks: data.enemyTypeHooks || [],
          environmentalContext: data.environmentalContext || '',
          estimatedCombatDifficulty: data.estimatedCombatDifficulty || 1,
        });
        break;
      case NodeType.Choice:
        Object.assign(typeData, {
          consequenceHooks: data.consequenceHooks || [],
          dilemmaType: data.dilemmaType,
        });
        break;
      case NodeType.Trade:
        Object.assign(typeData, {
          traderArchetype: data.traderArchetype || '',
          pricingHooks: data.pricingHooks || [],
        });
        break;
      case NodeType.Rest:
        Object.assign(typeData, {
          restType: data.restType,
          interruptionChance: data.interruptionChance,
          dreamHooks: data.dreamHooks,
        });
        break;
      case NodeType.Passage:
        Object.assign(typeData, {
          travelEventHooks: data.travelEventHooks || [],
          environmentalStorytelling: data.environmentalStorytelling || '',
          resourceCost: data.resourceCost,
        });
        break;
      case NodeType.StateCheck:
        Object.assign(typeData, {
          conditionHooks: data.conditionHooks || [],
          branchTargets: data.branchTargets,
        });
        break;
      case NodeType.Transition:
        Object.assign(typeData, {
          actChangeTrigger: data.actChangeTrigger,
          narrativeSummary: data.narrativeSummary || '',
          worldStateShifts: data.worldStateShifts || [],
        });
        break;
    }

    setFormData(typeData);
    nextStep();
  };

  const renderTypeForm = () => {
    switch (formData.type) {
      case NodeType.Combat:
        return <CombatForm />;
      case NodeType.Choice:
        return <ChoiceForm />;
      case NodeType.Trade:
        return <TradeForm />;
      case NodeType.Rest:
        return <RestForm />;
      case NodeType.Passage:
        return <PassageForm />;
      case NodeType.StateCheck:
        return <StateCheckForm />;
      case NodeType.Transition:
        return <TransitionForm />;
      default:
        return <p className="text-muted-foreground">Unknown node type</p>;
    }
  };

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit)} className="space-y-6">
        <div>
          <h2 className="text-xl font-semibold">{typeName} Properties</h2>
          <p className="text-sm text-muted-foreground">
            Configure type-specific properties for this {typeName.toLowerCase()} node
          </p>
        </div>

        {renderTypeForm()}

        <div className="flex justify-between pt-4">
          <Button type="button" variant="outline" onClick={prevStep}>
            Back
          </Button>
          <Button type="submit">Next</Button>
        </div>
      </form>
    </FormProvider>
  );
}

export function NodeCreatePage() {
  const { step, resetForm } = useFormStore();

  useEffect(() => {
    return () => {
      resetForm();
    };
  }, [resetForm]);

  const renderStep = () => {
    switch (step) {
      case 0:
        return <NodeTypeSelect />;
      case 1:
        return <BaseNodeForm />;
      case 2:
        return <TypeSpecificStep />;
      case 3:
        return <EligibilityBuilder />;
      case 4:
        return <ReviewStep />;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link
          to="/nodes"
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
          Back to nodes
        </Link>
      </div>

      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Create Node</h1>
          <p className="text-muted-foreground">
            Create a new game node with the wizard below
          </p>
        </div>
        <Link to="/generate?mode=quick">
          <Button variant="outline" className="gap-2">
            <Sparkles className="size-4" />
            Generate with AI
          </Button>
        </Link>
      </div>

      <StepIndicator currentStep={step} />

      <Card>
        <CardContent className="p-8">{renderStep()}</CardContent>
      </Card>
    </div>
  );
}
