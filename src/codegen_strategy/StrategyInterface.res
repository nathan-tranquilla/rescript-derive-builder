// Shared interface for all code generation handlers
module type Handler = {
  let canHandle: JSON.t => bool
  let handle: JSON.t => string
}
