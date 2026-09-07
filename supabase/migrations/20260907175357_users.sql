-- =============================================
-- MIGRATION: create_users_table
-- Cria a tabela public.users, espelhando o
-- auth.users do Supabase Auth via trigger.
-- =============================================

-- =============================================
-- TABELA
-- =============================================
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT,
  email       TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RLS
-- =============================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário vê apenas seu perfil" ON public.users;
DROP POLICY IF EXISTS "Usuário atualiza apenas seu perfil" ON public.users;

CREATE POLICY "Usuário vê apenas seu perfil"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Usuário atualiza apenas seu perfil"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- =============================================
-- TRIGGER: cria linha em public.users
-- automaticamente ao registrar em auth.users
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, username)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'username'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();