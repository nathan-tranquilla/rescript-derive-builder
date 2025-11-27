let canHandle = (json: JSON.t): bool => BuilderMetadata.isADotTType(json)

let handle = (json: JSON.t) => {
  let nameRes = BuilderMetadata.getFileName(json)
  let fieldDeclarations = BuilderMetadata.getFieldDeclarations(json)
  switch nameRes {
  | Ok(name) =>
    `open ${name}

type builderT = {
  ${fieldDeclarations
      ->Array.map(((name, signature, isOpt)) => {
        if isOpt {
          `${name}: ${signature}`
        } else {
          `${name}: option<${signature}>`
        }
      })
      ->Array.join(",\n  ")}
}

let empty = (): builderT => {
  ${fieldDeclarations
      ->Array.map(((name, _, _)) => `${name}: None`)
      ->Array.join(",\n  ")}
}

${fieldDeclarations
      ->Array.map(((name, signature, isOpt)) => {
        let valueAssignment = if isOpt {
          "val"
        } else {
          "Some(val)"
        }
        `let ${name} = (builder: builderT, val: ${signature}): builderT => {
  {...builder, ${name}: ${valueAssignment}}
}`
      })
      ->Array.join("\n\n")}

let build = (builder: builderT): result<${name}.t, string> => {
  ${{
        let requiredFields = fieldDeclarations->Array.filter(((_, _, isOpt)) => !isOpt)

        if requiredFields->Array.length === 0 {
          // No required fields, just build the record
          `Ok({${fieldDeclarations
            ->Array.map(((fieldName, _, isOpt)) =>
              if isOpt {
                `${fieldName}: builder.${fieldName}`
              } else {
                `${fieldName}: Option.getExn(builder.${fieldName})`
              }
            )
            ->Array.join(", ")}}: ${name}.t)`
        } else {
          // Has required fields - generate pattern match
          `switch (${fieldDeclarations
            ->Array.map(((fieldName, _, _)) => `builder.${fieldName}`)
            ->Array.join(", ")}) {
  | (${fieldDeclarations
            ->Array.map(((fieldName, _, _)) => `Some(${fieldName})`)
            ->Array.join(", ")}) => 
      Ok({${fieldDeclarations
            ->Array.map(((fieldName, _, _)) => `${fieldName}: ${fieldName}`)
            ->Array.join(", ")}}: ${name}.t)
  ${requiredFields
            ->Array.map(((fieldName, _, _)) => {
              let patternParts = fieldDeclarations->Array.map(((currentFieldName, _, _)) => {
                if fieldName === currentFieldName {
                  "None"
                } else {
                  "_"
                }
              })
              `| (${patternParts->Array.join(
                  ", ",
                )}) => Error("Missing required field: ${fieldName}")`
            })
            ->Array.join("\n  ")}
  }`
        }
      }}
}
`
  | _ => ""
  }
}
