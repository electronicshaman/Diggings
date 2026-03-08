import { useQuery } from '@tanstack/react-query';
import { getCards, getCard, type CardsParams } from '../lib/api';

export function useCards(filters: CardsParams = {}) {
  return useQuery({
    queryKey: ['cards', filters],
    queryFn: () => getCards(filters),
  });
}

export function useCard(cardId: string | undefined) {
  return useQuery({
    queryKey: ['card', cardId],
    queryFn: () => getCard(cardId!),
    enabled: !!cardId,
  });
}
