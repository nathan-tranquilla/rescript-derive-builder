module JsonKeys = {
  let docstrings = "docstrings"
  let name = "name"
  let items = "items"
  let detail = "detail"
  let signature = "signature"
  let optional = "optional"
}

let builderAttribute = "@@deriving(builder)"

let getStringArray = (json: JSON.t): option<array<string>> =>
  json
  ->JSON.Decode.array
  ->Option.map(arr => arr->Array.filterMap(JSON.Decode.string))

let getObjectArray = (json: JSON.t): option<array<dict<JSON.t>>> =>
  json
  ->JSON.Decode.array
  ->Option.map(arr => arr->Array.filterMap(JSON.Decode.object))

let hasBuilderDerivation = (docstrings: array<string>): bool =>
  docstrings->Array.some(docstring => docstring->String.includes(builderAttribute))

let checkItemForBuilder = (item: dict<JSON.t>): bool =>
  item
  ->Dict.get(JsonKeys.docstrings)
  ->Option.flatMap(getStringArray)
  ->Option.map(hasBuilderDerivation)
  ->Option.getOr(false)

let getFileName = (json: JSON.t): result<string, string> => {
  json
  ->JSON.Decode.object
  ->Option.flatMap(dict => dict->Dict.get(JsonKeys.name))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.mapOr(Error(`No '${JsonKeys.name}' found`), name => Ok(name))
}

let getItemsOpt = (json: JSON.t): option<array<JSON.t>> => {
  json
  ->JSON.Decode.object
  ->Option.flatMap(dict => dict->Dict.get(JsonKeys.items))
  ->Option.flatMap(JSON.Decode.array)
}

let isADotTType = (json: JSON.t): bool => {
  json
  ->getItemsOpt
  ->Option.flatMap(arr => arr->Array.get(0))
  ->Option.flatMap(JSON.Decode.object)
  ->Option.flatMap(dict => dict->Dict.get(JsonKeys.name))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.map(name => name->String.equal("t"))
  ->Option.getOr(false)
}

let getFieldDeclarations = (json: JSON.t): array<(string, string, bool)> => {
  json
  ->getItemsOpt
  ->Option.map(arrJson =>
    arrJson->Array.flatMap(json' => {
      json'
      ->JSON.Decode.object
      ->Option.flatMap(dict => dict->Dict.get(JsonKeys.detail))
      ->Option.flatMap(JSON.Decode.object)
      ->Option.flatMap(dict => dict->Dict.get(JsonKeys.items))
      ->Option.flatMap(JSON.Decode.array)
      ->Option.map(
        fieldsArray =>
          fieldsArray->Array.filterMap(
            fieldJson => {
              fieldJson
              ->JSON.Decode.object
              ->Option.flatMap(
                fieldDict => {
                  let name = fieldDict->Dict.get(JsonKeys.name)->Option.flatMap(JSON.Decode.string)
                  let signature =
                    fieldDict->Dict.get(JsonKeys.signature)->Option.flatMap(JSON.Decode.string)
                  let isOptional =
                    fieldDict->Dict.get(JsonKeys.optional)->Option.flatMap(JSON.Decode.bool)
                  switch (name, signature, isOptional) {
                  | (Some(n), Some(s), Some(o)) => Some((n, s, o))
                  | _ => None
                  }
                },
              )
            },
          ),
      )
      ->Option.getOr([])
    })
  )
  ->Option.getOr([])
}
