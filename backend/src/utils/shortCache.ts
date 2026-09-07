type CacheEntry<T> = {
  value: T
  expiresAt: number
}

export class ShortCache<T> {
  private store = new Map<string, CacheEntry<T>>()

  constructor(private defaultTtlMs: number) {}

  get(key: string): T | undefined {
    const entry = this.store.get(key)

    if (!entry) {
      return undefined
    }

    if (Date.now() >= entry.expiresAt) {
      this.store.delete(key)
      return undefined
    }

    return entry.value
  }

  set(key: string, value: T, ttlMs = this.defaultTtlMs): void {
    this.store.set(key, {
      value,
      expiresAt: Date.now() + ttlMs,
    })
  }

  delete(key: string): void {
    this.store.delete(key)
  }

  deleteByPrefix(prefix: string): void {
    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) {
        this.store.delete(key)
      }
    }
  }
}

export function buildFilterCacheKey(
  userId: string,
  parts: Record<string, unknown>
): string {
  return `${userId}:${JSON.stringify(parts)}`
}

/** Cache de metadados de listagem (30s). */
export const listMetaCache = new ShortCache<{
  summary_total: number
  has_any: boolean
  available_years: number[]
}>(30_000)

/** Cache de opções de filtro — anos/meses (60s). */
export const filterOptionsCache = new ShortCache<{
  years: number[]
  months: number[]
}>(60_000)
