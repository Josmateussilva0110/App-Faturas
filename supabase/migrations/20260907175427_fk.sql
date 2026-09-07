-- =============================================
-- MIGRATION: users_drop_password_add_named_fk
-- Ajustes na tabela public.users:
--  1) Remove coluna password (não deve existir,
--     autenticação é 100% gerenciada pelo Supabase Auth)
--  2) Garante FK nomeada users_id_fkey
--     (idempotente - só cria se ainda não existir,
--     já que a tabela nasce com FK inline em id)
-- =============================================

-- 1. Remove coluna password se existir
ALTER TABLE public.users DROP COLUMN IF EXISTS password;

-- 2. Garante a FK nomeada, evitando erro de constraint duplicada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'users_id_fkey'
      AND conrelid = 'public.users'::regclass
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT users_id_fkey
      FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;