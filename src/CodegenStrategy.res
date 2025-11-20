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

module DotTHandler = {
  let handle = (json: JSON.t) => {
    let nameRes = BuilderMetadata.getFileName(json)
    let fieldDeclarations = BuilderMetadata.getFieldDeclarations(json)
    switch nameRes {
    | Ok(name) =>
      ` 
        module ${name->String.charAt(0)->String.toUpperCase}${name->String.sliceToEnd(
          ~start=1,
        )}Builder = {
          type t = {
            ${fieldDeclarations
        ->Array.map(((name, signature)) => `${name}: option<${signature}>`)
        ->Array.join(",\n            ")}
          }
          
          let empty = () => {
            ${fieldDeclarations
        ->Array.map(((name, _)) => `${name}: None`)
        ->Array.join(",\n            ")}
          }

          ${fieldDeclarations
        ->Array.map(((name, signature)) =>
          `
          let ${name} = (builder: t, val: ${signature}): t => {
            {...builder, ${name}: Some(val)}
          }`
        )
        ->Array.join("\n\n          ")}
          
          let build = (builder: t): result<${name}.t, string> => {
            switch (${fieldDeclarations
        ->Array.map(((name, _)) => `builder.${name}`)
        ->Array.join(", ")}) {
            | (${fieldDeclarations
        ->Array.map(((name, _)) => `Some(${name})`)
        ->Array.join(", ")}) => 
                Ok({${fieldDeclarations
        ->Array.map(((name, _)) => `${name}: ${name}`)
        ->Array.join(", ")}})
            | _ => Error("Missing required fields")
            }
          }
        }
      `
    | _ => ""
    }
  }
}

module CodegenStrategyCoordinator = {
  let generalStrategyHandler = {
    strategy: {
      handle: _json => "//TODO: Implement general code generation strategy",
      canHandle: _json => true,
    },
    next: None,
  }

  let dotTStrategyHandler = {
    strategy: {
      handle: DotTHandler.handle,
      canHandle: json => BuilderMetadata.isADotTType(json),
    },
    next: Some(generalStrategyHandler),
  }

  let exec = (json: JSON.t): result<string, string> => {
    execute(json, dotTStrategyHandler)
  }
}
