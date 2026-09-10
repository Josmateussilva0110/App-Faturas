-- =============================================
-- MIGRATION: deposit
-- Salários e despesas fixas da tela "Depositar",
-- mais o limite de gastos do usuário.
-- =============================================

-- =============================================
-- TABELA: salaries
-- =============================================
CREATE TABLE IF NOT EXISTS public.salaries (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  amount     NUMERIC(12, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT salaries_name_not_blank  CHECK (length(btrim(name)) > 0),
  CONSTRAINT salaries_amount_positive CHECK (amount > 0)
);

-- Consulta do app: as linhas do usuário na ordem em que ele as criou.
CREATE INDEX IF NOT EXISTS salaries_user_id_created_at_idx
  ON public.salaries (user_id, created_at);

DROP TRIGGER IF EXISTS salaries_set_updated_at ON public.salaries;
CREATE TRIGGER salaries_set_updated_at
  BEFORE UPDATE ON public.salaries
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================
-- TABELA: expenses
-- Mesma forma de salaries. A ordem das linhas é
-- semântica: o app desconta uma a uma e mostra o
-- saldo corrente sob cada despesa, então a ordem
-- de inserção precisa sobreviver.
-- =============================================
CREATE TABLE IF NOT EXISTS public.expenses (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  amount     NUMERIC(12, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT expenses_name_not_blank  CHECK (length(btrim(name)) > 0),
  CONSTRAINT expenses_amount_positive CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS expenses_user_id_created_at_idx
  ON public.expenses (user_id, created_at);

DROP TRIGGER IF EXISTS expenses_set_updated_at ON public.expenses;
CREATE TRIGGER expenses_set_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================
-- COLUNA: users.spending_limit
-- Meta mensal de gastos no cartão. NULL = sem
-- meta definida.
-- =============================================
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS spending_limit NUMERIC(12, 2);

ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_spending_limit_positive;
ALTER TABLE public.users
  ADD CONSTRAINT users_spending_limit_positive
  CHECK (spending_limit IS NULL OR spending_limit > 0);

-- =============================================
-- RLS
-- Cada usuário enxerga e altera apenas o que é seu.
-- =============================================
ALTER TABLE public.salaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário vê apenas seus salários" ON public.salaries;
DROP POLICY IF EXISTS "Usuário insere apenas seus salários" ON public.salaries;
DROP POLICY IF EXISTS "Usuário atualiza apenas seus salários" ON public.salaries;
DROP POLICY IF EXISTS "Usuário remove apenas seus salários" ON public.salaries;

CREATE POLICY "Usuário vê apenas seus salários"
  ON public.salaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Usuário insere apenas seus salários"
  ON public.salaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário atualiza apenas seus salários"
  ON public.salaries FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário remove apenas seus salários"
  ON public.salaries FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário vê apenas suas despesas" ON public.expenses;
DROP POLICY IF EXISTS "Usuário insere apenas suas despesas" ON public.expenses;
DROP POLICY IF EXISTS "Usuário atualiza apenas suas despesas" ON public.expenses;
DROP POLICY IF EXISTS "Usuário remove apenas suas despesas" ON public.expenses;

CREATE POLICY "Usuário vê apenas suas despesas"
  ON public.expenses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Usuário insere apenas suas despesas"
  ON public.expenses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário atualiza apenas suas despesas"
  ON public.expenses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário remove apenas suas despesas"
  ON public.expenses FOR DELETE USING (auth.uid() = user_id);
