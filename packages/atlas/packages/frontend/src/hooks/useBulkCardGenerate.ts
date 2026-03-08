import { useState, useRef } from 'react';

interface CompletedCard {
  index: number;
  cardId: string;
  name: string;
  cardType: string;
  rarity: string;
}

interface FailedCard {
  index: number;
  cardType: string;
  rarity: string;
  error: string;
}

interface BulkPlanItem {
  cardType: string;
  rarity: string;
  count: number;
}

export interface BulkCardState {
  status: 'idle' | 'running' | 'completed' | 'error';
  jobId: string | null;
  totalCards: number;
  currentIndex: number;
  plan: BulkPlanItem[];
  completed: CompletedCard[];
  failed: FailedCard[];
  errorMessage: string | null;
}

export interface BulkCardGenerateParams {
  targetTotal: number;
  cardOwner?: string;
}

const INITIAL_STATE: BulkCardState = {
  status: 'idle',
  jobId: null,
  totalCards: 0,
  currentIndex: 0,
  plan: [],
  completed: [],
  failed: [],
  errorMessage: null,
};

export function useBulkCardGenerate() {
  const [state, setState] = useState<BulkCardState>(INITIAL_STATE);
  const abortRef = useRef<AbortController | null>(null);

  function reset() {
    setState(INITIAL_STATE);
  }

  function cancel() {
    abortRef.current?.abort();
    setState((prev) => ({
      ...prev,
      status: prev.status === 'running' ? 'completed' : prev.status,
    }));
  }

  async function start(params: BulkCardGenerateParams) {
    if (state.status === 'running') return;

    const controller = new AbortController();
    abortRef.current = controller;

    setState({ ...INITIAL_STATE, status: 'running' });

    try {
      const response = await fetch('/api/generate/cards/bulk', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'text/event-stream',
        },
        body: JSON.stringify({
          targetTotal: params.targetTotal,
          ...(params.cardOwner ? { cardOwner: params.cardOwner } : {}),
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const err = await response.json().catch(() => ({ error: 'Request failed' }));
        setState((prev) => ({
          ...prev,
          status: 'error',
          errorMessage: err.error || 'Request failed',
        }));
        return;
      }

      if (!response.body) {
        setState((prev) => ({ ...prev, status: 'error', errorMessage: 'No response body' }));
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      // SSE parsing loop
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        // Split on double newline (SSE event boundaries)
        const events = buffer.split('\n\n');
        buffer = events.pop() ?? '';

        for (const eventText of events) {
          if (!eventText.trim()) continue;

          let eventType = 'message';
          let dataStr = '';

          for (const line of eventText.split('\n')) {
            if (line.startsWith('event: ')) {
              eventType = line.slice(7).trim();
            } else if (line.startsWith('data: ')) {
              dataStr = line.slice(6);
            }
          }

          if (!dataStr) continue;

          let data: Record<string, unknown>;
          try {
            data = JSON.parse(dataStr);
          } catch {
            continue;
          }

          switch (eventType) {
            case 'bulk_start':
              setState((prev) => ({
                ...prev,
                jobId: data.jobId as string,
                totalCards: data.totalCards as number,
                plan: (data.plan as BulkPlanItem[]) ?? [],
              }));
              break;

            case 'card_start':
              setState((prev) => ({
                ...prev,
                currentIndex: data.index as number,
              }));
              break;

            case 'card_complete':
              setState((prev) => ({
                ...prev,
                currentIndex: (data.index as number) + 1,
                completed: [
                  ...prev.completed,
                  {
                    index: data.index as number,
                    cardId: data.cardId as string,
                    name: data.name as string,
                    cardType: data.cardType as string,
                    rarity: data.rarity as string,
                  },
                ],
              }));
              break;

            case 'card_error':
              setState((prev) => ({
                ...prev,
                failed: [
                  ...prev.failed,
                  {
                    index: data.index as number,
                    cardType: (data.cardType as string) ?? 'Unknown',
                    rarity: (data.rarity as string) ?? 'Unknown',
                    error: data.error as string,
                  },
                ],
              }));
              break;

            case 'bulk_complete':
              setState((prev) => ({
                ...prev,
                status: 'completed',
                totalCards: data.totalCards as number,
              }));
              break;

            case 'ping':
              // keep-alive, ignore
              break;
          }
        }
      }

      setState((prev) => {
        if (prev.status === 'running') return { ...prev, status: 'completed' };
        return prev;
      });
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        setState((prev) => ({ ...prev, status: 'completed' }));
      } else {
        const msg = err instanceof Error ? err.message : String(err);
        setState((prev) => ({ ...prev, status: 'error', errorMessage: msg }));
      }
    }
  }

  return { state, start, cancel, reset };
}
