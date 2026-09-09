import { Card } from "../../types/cards/card"

type CardRow = {
  id: string
  name: string
}

export function mapCardRow(row: CardRow): Card {
  return {
    id: row.id,
    name: row.name,
  }
}
