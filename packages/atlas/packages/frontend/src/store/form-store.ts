import { create } from 'zustand';
import type { AnyNodeMetadata } from '@node-gen-web/shared';

export type WizardStep = 0 | 1 | 2 | 3 | 4;

interface FormState {
  step: WizardStep;
  formData: Partial<AnyNodeMetadata>;
  setStep: (step: WizardStep) => void;
  nextStep: () => void;
  prevStep: () => void;
  setFormData: (data: Partial<AnyNodeMetadata>) => void;
  resetForm: () => void;
}

export const useFormStore = create<FormState>()((set) => ({
  step: 0,
  formData: {},
  setStep: (step) => set({ step }),
  nextStep: () =>
    set((state) => ({
      step: Math.min(state.step + 1, 4) as WizardStep,
    })),
  prevStep: () =>
    set((state) => ({
      step: Math.max(state.step - 1, 0) as WizardStep,
    })),
  setFormData: (data) =>
    set((state) => ({
      formData: { ...state.formData, ...data },
    })),
  resetForm: () => set({ step: 0, formData: {} }),
}));
