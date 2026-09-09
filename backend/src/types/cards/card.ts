export interface Card {
  id: string
  name: string
}

/** Retorno de create e update: o cliente já tem o resto do payload. */
export interface CreatedCard {
  id: string
}
