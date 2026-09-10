export interface Card {
  id: string
  name: string
  /** Matiz 0-359 escolhido pelo usuário, ou null para "automática". */
  color_hue: number | null
}

/** Retorno de create e update: o cliente já tem o resto do payload. */
export interface CreatedCard {
  id: string
}
