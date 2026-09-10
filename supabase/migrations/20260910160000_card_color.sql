-- =============================================
-- MIGRATION: cor do cartão
-- Deixa o usuário escolher a cor com que o
-- cartão aparece nas listas.
-- =============================================

-- Guarda o matiz (0-359), não uma cor pronta: o app deriva a cor final dele
-- com claridade diferente para tema claro e escuro (AppColors.avatarBackground).
-- Um hex fixo ficaria calibrado para um dos dois temas e destoaria no outro.
--
-- Nulo significa "automática": o app cai no hash do nome, que é o
-- comportamento que os cartões já existentes tinham antes desta coluna.
ALTER TABLE public.cards
  ADD COLUMN IF NOT EXISTS color_hue INTEGER;

ALTER TABLE public.cards
  DROP CONSTRAINT IF EXISTS cards_color_hue_range;
ALTER TABLE public.cards
  ADD CONSTRAINT cards_color_hue_range
  CHECK (color_hue IS NULL OR color_hue BETWEEN 0 AND 359);
