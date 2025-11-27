// Shared interface module type for all handlers
module type Handler = {
  let canHandle: JSON.t => bool
  let handle: JSON.t => string
}
