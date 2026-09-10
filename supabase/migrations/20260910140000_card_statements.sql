-- =============================================
-- MIGRATION: card_statements
-- O valor da fatura que o banco mostra, por
-- cartão e por mês. Serve para conferir o que
-- está lançado no app contra a fatura real.
-- =============================================

CREATE TABLE IF NOT EXISTS public.card_statements (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Diferente de purchases, aqui é CASCADE: uma conferência sem o cartão a
  -- que ela pertence não significa nada.
  card_id    UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,

  -- Mês absoluto (year * 12 + mês0), mesma convenção de purchases.start_abs.
  month_abs  INTEGER NOT NULL,

  amount     NUMERIC(12, 2) NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT card_statements_amount_positive CHECK (amount > 0),
  CONSTRAINT card_statements_month_abs_range CHECK (month_abs BETWEEN 24000 AND 30000)
);

-- A identidade da linha é (cartão, mês), não o id: um cartão tem uma fatura
-- por mês. Como índice único, duas requisições simultâneas não conseguem
-- gravar duas faturas do mesmo mês — é o que sustenta o upsert no service.
CREATE UNIQUE INDEX IF NOT EXISTS card_statements_card_id_month_abs_unique
  ON public.card_statements (card_id, month_abs);

-- Consulta do app: as conferências do usuário, do mês mais recente para trás.
CREATE INDEX IF NOT EXISTS card_statements_user_id_month_abs_idx
  ON public.card_statements (user_id, month_abs DESC);

DROP TRIGGER IF EXISTS card_statements_set_updated_at ON public.card_statements;
CREATE TRIGGER card_statements_set_updated_at
  BEFORE UPDATE ON public.card_statements
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================
-- RLS
-- =============================================
ALTER TABLE public.card_statements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário vê apenas suas faturas" ON public.card_statements;
DROP POLICY IF EXISTS "Usuário insere apenas suas faturas" ON public.card_statements;
DROP POLICY IF EXISTS "Usuário atualiza apenas suas faturas" ON public.card_statements;
DROP POLICY IF EXISTS "Usuário remove apenas suas faturas" ON public.card_statements;

CREATE POLICY "Usuário vê apenas suas faturas"
  ON public.card_statements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Usuário insere apenas suas faturas"
  ON public.card_statements FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário atualiza apenas suas faturas"
  ON public.card_statements FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário remove apenas suas faturas"
  ON public.card_statements FOR DELETE USING (auth.uid() = user_id);
