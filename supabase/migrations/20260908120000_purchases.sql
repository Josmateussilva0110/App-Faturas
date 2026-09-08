-- =============================================
-- MIGRATION: purchases
-- Compras no cartão, possivelmente parceladas.
-- Cria também public.cards, que as compras
-- referenciam.
-- =============================================

-- Mantém updated_at coerente sem depender do backend lembrar de setar.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TABELA: cards
-- =============================================
CREATE TABLE IF NOT EXISTS public.cards (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT cards_name_not_blank CHECK (length(btrim(name)) > 0)
);

CREATE INDEX IF NOT EXISTS cards_user_id_idx ON public.cards (user_id);

DROP TRIGGER IF EXISTS cards_set_updated_at ON public.cards;
CREATE TRIGGER cards_set_updated_at
  BEFORE UPDATE ON public.cards
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================
-- TABELA: purchases
-- =============================================
CREATE TABLE IF NOT EXISTS public.purchases (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  -- Cartão apagado não apaga a compra: o app mostra "Cartão removido".
  card_id      UUID REFERENCES public.cards(id) ON DELETE SET NULL,

  name         TEXT NOT NULL,
  amount       NUMERIC(12, 2) NOT NULL,
  installments INTEGER NOT NULL,

  -- Compra de outra pessoa: person guarda o nome. Quando é do próprio
  -- usuário, is_other = false e person fica vazio.
  is_other     BOOLEAN NOT NULL DEFAULT FALSE,
  person       TEXT NOT NULL DEFAULT '',

  -- Mês absoluto (year * 12 + mês0) em que a primeira parcela cai. Evita
  -- tratar virada de ano como caso especial no cálculo das parcelas.
  start_abs    INTEGER NOT NULL,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT purchases_name_not_blank  CHECK (length(btrim(name)) > 0),
  CONSTRAINT purchases_amount_positive CHECK (amount > 0),
  CONSTRAINT purchases_installments_min CHECK (installments >= 1),
  CONSTRAINT purchases_start_abs_range CHECK (start_abs BETWEEN 24000 AND 30000),

  -- Impede o estado inconsistente de "é de outra pessoa" sem nome, e de
  -- sobrar nome numa compra própria.
  CONSTRAINT purchases_person_matches_is_other CHECK (
    (is_other = TRUE  AND length(btrim(person)) > 0) OR
    (is_other = FALSE AND person = '')
  )
);

-- Consulta principal do app: as compras do usuário a partir de um mês.
CREATE INDEX IF NOT EXISTS purchases_user_id_start_abs_idx
  ON public.purchases (user_id, start_abs DESC);

CREATE INDEX IF NOT EXISTS purchases_card_id_idx ON public.purchases (card_id);

DROP TRIGGER IF EXISTS purchases_set_updated_at ON public.purchases;
CREATE TRIGGER purchases_set_updated_at
  BEFORE UPDATE ON public.purchases
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================
-- RLS
-- Cada usuário enxerga e altera apenas o que é seu.
-- =============================================
ALTER TABLE public.cards     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário vê apenas seus cartões" ON public.cards;
DROP POLICY IF EXISTS "Usuário insere apenas seus cartões" ON public.cards;
DROP POLICY IF EXISTS "Usuário atualiza apenas seus cartões" ON public.cards;
DROP POLICY IF EXISTS "Usuário remove apenas seus cartões" ON public.cards;

CREATE POLICY "Usuário vê apenas seus cartões"
  ON public.cards FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Usuário insere apenas seus cartões"
  ON public.cards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário atualiza apenas seus cartões"
  ON public.cards FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário remove apenas seus cartões"
  ON public.cards FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuário vê apenas suas compras" ON public.purchases;
DROP POLICY IF EXISTS "Usuário insere apenas suas compras" ON public.purchases;
DROP POLICY IF EXISTS "Usuário atualiza apenas suas compras" ON public.purchases;
DROP POLICY IF EXISTS "Usuário remove apenas suas compras" ON public.purchases;

CREATE POLICY "Usuário vê apenas suas compras"
  ON public.purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Usuário insere apenas suas compras"
  ON public.purchases FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário atualiza apenas suas compras"
  ON public.purchases FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuário remove apenas suas compras"
  ON public.purchases FOR DELETE USING (auth.uid() = user_id);
