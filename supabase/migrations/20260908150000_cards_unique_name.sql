-- =============================================
-- MIGRATION: cards_unique_name
-- Impede dois cartões com o mesmo nome para o
-- mesmo usuário.
-- =============================================

-- A comparação normaliza caixa e espaços: "Nubank", "nubank" e " Nubank "
-- são o mesmo cartão do ponto de vista de quem cadastra, e permitir os três
-- só criaria confusão na hora de escolher o cartão da compra.
--
-- Feito como índice único, e não como verificação antes do insert, porque
-- duas requisições simultâneas passariam pela verificação e gravariam as
-- duas. O banco é o único lugar onde essa garantia não tem corrida.
--
-- Se a tabela já tiver duplicatas, a criação falha — nesse caso, renomeie
-- ou remova as repetidas antes de aplicar.
CREATE UNIQUE INDEX IF NOT EXISTS cards_user_id_name_unique
  ON public.cards (user_id, lower(btrim(name)));
