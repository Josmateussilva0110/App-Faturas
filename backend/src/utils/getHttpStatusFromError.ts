export function getHttpStatusFromError<T extends string>(
  code: T,
  map: Record<T, number>,
  fallback = 400
): number {
  return map[code] ?? fallback
}
