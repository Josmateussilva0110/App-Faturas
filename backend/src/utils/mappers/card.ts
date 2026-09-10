import { Card } from "../../types/cards/card"

type CardRow = {
  id: string
  name: string
  color_hue: number | null
}

export function mapCardRow(row: CardRow): Card {
  return {
    id: row.id,
    name: row.name,
    color_hue: row.color_hue,
  }
}
