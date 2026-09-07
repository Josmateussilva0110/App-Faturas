-- =============================================
-- MIGRATION: password_flow
-- Troca de senha e solicitações de reset manual
-- =============================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.password_reset_requests (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES public.users(id) ON DELETE SET NULL,
  identifier   TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'pending',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at  TIMESTAMPTZ,
  resolved_by  TEXT,

  CONSTRAINT password_reset_requests_status_check
    CHECK (status IN ('pending', 'contacted', 'resolved', 'rejected'))
);

CREATE INDEX IF NOT EXISTS password_reset_requests_status_idx
  ON public.password_reset_requests (status, requested_at DESC);

CREATE INDEX IF NOT EXISTS password_reset_requests_user_id_idx
  ON public.password_reset_requests (user_id);

ALTER TABLE public.password_reset_requests ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.password_reset_requests FROM authenticated;
GRANT ALL ON public.password_reset_requests TO service_role;