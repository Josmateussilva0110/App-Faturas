type OnRefreshedCallback = (
  accessToken: string,
  refreshToken: string,
  expiresAt: number
) => void;

type OnExpiredCallback = () => void;

class TokenManager {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  /**
   * Controle de refresh
   */
  private refreshing = false;
  private refreshPromise: Promise<void> | null = null;

  /**
   * Eventos
   */
  private refreshedListeners = new Set<OnRefreshedCallback>();
  private expiredListeners = new Set<OnExpiredCallback>();

  // =========================
  // TOKENS
  // =========================

  getAccessToken(): string | null {
    return this.accessToken;
  }

  getRefreshToken(): string | null {
    return this.refreshToken;
  }

  setTokens(access: string, refresh: string) {
    this.accessToken = access;
    this.refreshToken = refresh;
  }

  clearTokens() {
    this.accessToken = null;
    this.refreshToken = null;
  }

  // =========================
  // REFRESH
  // =========================

  isRefreshing(): boolean {
    return this.refreshing;
  }

  /**
   * Chamado pelo RefreshService
   */
  startRefresh(promise: Promise<void>) {
    this.refreshing = true;
    this.refreshPromise = promise;
  }

  /**
   * Chamado quando o refresh termina
   */
  finishRefresh() {
    this.refreshing = false;
    this.refreshPromise = null;
  }

  /**
   * Qualquer request pode aguardar
   * o refresh terminar.
   */
  async waitRefresh(): Promise<void> {
    if (!this.refreshPromise) {
      return;
    }

    try {
      await this.refreshPromise;
    } catch {
      // erro será tratado por quem iniciou o refresh
    }
  }

  // =========================
  // LISTENERS
  // =========================

  onRefreshed(cb: OnRefreshedCallback): () => void {
    this.refreshedListeners.add(cb);

    return () => {
      this.refreshedListeners.delete(cb);
    };
  }

  onExpired(cb: OnExpiredCallback): () => void {
    this.expiredListeners.add(cb);

    return () => {
      this.expiredListeners.delete(cb);
    };
  }

  notifyRefreshed(
    accessToken: string,
    refreshToken: string,
    expiresAt: number
  ) {
    this.refreshedListeners.forEach((listener) =>
      listener(accessToken, refreshToken, expiresAt)
    );
  }

  notifyExpired() {
    this.expiredListeners.forEach((listener) => listener());
  }
}

export const tokenManager = new TokenManager();