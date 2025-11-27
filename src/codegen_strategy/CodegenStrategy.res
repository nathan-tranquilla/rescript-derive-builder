// Core types for the strategy pattern
type canHandle = JSON.t => bool
type handle = JSON.t => string

type strategy = {
  canHandle: canHandle,
  handle: handle,
}

type rec handler = {
  strategy: strategy,
  next: option<handler>,
}

// Main execution engine
let rec execute = (json: JSON.t, handler: handler): result<string, string> => {
  if !handler.strategy.canHandle(json) {
    switch handler.next {
    | Some(next) => execute(json, next)
    | None => Error("Cannot resolve strategy for code generation")
    }
  } else {
    Ok(handler.strategy.handle(json))
  }
}

module CodegenStrategyCoordinator = {
  // Private helper for creating strategy records
  let makeStrategy = (~canHandle, ~handle): strategy => {
    canHandle,
    handle,
  }

  // Strategy definitions
  let generalStrategy = makeStrategy(
    ~canHandle=_json => true,
    ~handle=_json => "//TODO: Implement general code generation strategy",
  )

  let dotTStrategy = makeStrategy(
    ~canHandle=MainTypeHandler.canHandle,
    ~handle=MainTypeHandler.handle,
  )

  // Handler chain construction
  let generalStrategyHandler = {
    strategy: generalStrategy,
    next: None,
  }

  let dotTStrategyHandler = {
    strategy: dotTStrategy,
    next: Some(generalStrategyHandler),
  }

  // Public API
  let exec = (json: JSON.t): result<string, string> => {
    execute(json, dotTStrategyHandler)
  }
}
