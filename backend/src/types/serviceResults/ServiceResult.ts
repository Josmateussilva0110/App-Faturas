export type ServiceResult<T = void, E extends string = string> =
  | {
      status: true
      data: T
    }
  | {
      status: false
      error: {
        code: E
        message?: string
      }
    }

