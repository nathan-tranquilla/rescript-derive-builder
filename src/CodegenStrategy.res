type canHandle = JSON.t => bool
type handle = JSON.t => string

type strategy = {
  canHandle: canHandle,
  handle: handle,
  name: string, 
}

type rec handler = {
  strategy: strategy,
  next: option<handler>
}

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
  
  let generalStrategyHandler = {
    strategy: {
      name: "GeneralStrategy",
      handle: (json) => "code generated from general strategy",
      canHandle: (json) => true
    },
    next: None
  }

  let dotTStrategyHandler = {
    strategy: {
      name: "DotTStrategy",
      handle: (json) => "Code generated from dot t strategy",
      canHandle: (json) => BuilderMetadata.isADotTType(json)
    },
    next: Some(generalStrategyHandler)
  }

  let exec = (json: JSON.t): result<string, string> => {
    execute(json, dotTStrategyHandler)
  } 
}



