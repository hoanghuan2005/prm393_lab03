import type { BudgetLine, OwnedLine, SaleDay } from '../../types';
import { AuthError } from '../../lib/api';
import { api, getPairing, handleRevoked } from '../pairing/pairing';
import { defaultSaleCalendar } from './rules';

export interface DecisionContext { budgets: BudgetLine[] | null; calendar: SaleDay[]; owned: OwnedLine[] | null; linked: boolean; revoked?: boolean; }

export async function loadDecisionContext(): Promise<DecisionContext> {
  const p = await getPairing();
  if (!p.linked || !p.token) return { budgets: null, calendar: defaultSaleCalendar(), owned: null, linked: false };
  try {
    const [budgets, calendar, owned] = await Promise.all([api().budgets(p.token), api().saleCalendar(p.token), api().owned(p.token)]);
    return { budgets, calendar: calendar.length ? calendar : defaultSaleCalendar(), owned, linked: true };
  } catch (e) {
    if (e instanceof AuthError) { await handleRevoked(); return { budgets: null, calendar: defaultSaleCalendar(), owned: null, linked: false, revoked: true }; }
    return { budgets: null, calendar: defaultSaleCalendar(), owned: null, linked: true };
  }
}
