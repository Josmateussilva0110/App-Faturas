export type SupabaseError = {
  code?: string
  message?: string
}

export function isUniqueViolation(error: SupabaseError | null | undefined) {
  return error?.code === "23505"
}

export function isForeignKeyViolation(error: SupabaseError | null | undefined) {
  return error?.code === "23503"
}
