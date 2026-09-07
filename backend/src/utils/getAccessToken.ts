import { Request } from "express"

export function getAccessToken(request: Request): string {
  return request.accessToken ?? request.headers.authorization!.split(" ")[1]
}
