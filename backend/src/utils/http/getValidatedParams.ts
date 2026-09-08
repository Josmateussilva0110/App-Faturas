import { Request } from "express"

/**
 * Lê os params já validados por `validate(Schema, "params")`.
 *
 * O `validate` guarda o resultado em `validatedParams` como `unknown`, para
 * não fingir que `request.params` (sempre string) tem o tipo do schema. Este
 * helper concentra o cast num lugar só.
 *
 * Fica fora dos controllers de propósito: os métodos são passados soltos
 * para o Express (`router.get(..., Controller.list)`), então `this` é
 * `undefined` dentro deles e um método privado quebraria em runtime.
 */
export function getValidatedParams<T>(request: Request): T {
  return request.validatedParams as T
}
