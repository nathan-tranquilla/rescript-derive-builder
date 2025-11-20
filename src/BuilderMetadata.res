/**
 {
  "name": "Demo",
  "docstrings": [],
  "source": {
    "filepath": "src/Demo.res",
    "line": 1,
    "col": 1
  },
  "items": [
  {
    "id": "Demo.t",
    "kind": "type",
    "name": "t",
    "signature": "type t = {name: string, age: int, socialSecurity?: int}",
    "docstrings": ["@@deriving(builder)"],
    "source": {
      "filepath": "src/Demo.res",
      "line": 4,
      "col": 1
    },
    "detail": 
    {
      "kind": "record",
      "items": [{
        "name": "name",
        "optional": false,
        "docstrings": [],
        "signature": "string"
      }, {
        "name": "age",
        "optional": false,
        "docstrings": [],
        "signature": "int"
      }, {
        "name": "socialSecurity",
        "optional": true,
        "docstrings": [],
        "signature": "option<int>"
      }]
    }
  }]
}
 */
let getStringArray = (json: JSON.t): option<array<string>> =>
  json
  ->JSON.Decode.array
  ->Option.map(arr => arr->Array.filterMap(JSON.Decode.string))

let getObjectArray = (json: JSON.t): option<array<Js.Dict.t<JSON.t>>> =>
  json
  ->JSON.Decode.array
  ->Option.map(arr => arr->Array.filterMap(JSON.Decode.object))

let hasBuilderDerivation = (docstrings: array<string>): bool =>
  docstrings->Array.some(docstring => docstring->String.equal("@@deriving(builder)"))

let checkItemForBuilder = (item: Js.Dict.t<JSON.t>): bool =>
  item
  ->Dict.get("docstrings")
  ->Option.flatMap(getStringArray)
  ->Option.map(hasBuilderDerivation)
  ->Option.getOr(false)

let getFileName = (json: JSON.t): result<string, string> => {
  json
  ->JSON.Decode.object
  ->Option.flatMap(dict => dict->Dict.get("name"))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.mapOr(Error("No 'name' found"), name => Ok(name))
}

let getItemsOpt = (json: JSON.t): option<array<JSON.t>> => {
  json
  ->JSON.Decode.object
  ->Option.flatMap(dict => dict->Dict.get("items"))
  ->Option.flatMap(JSON.Decode.array)
}

let isADotTType = (json: JSON.t): bool => {
  json
  ->getItemsOpt
  ->Option.flatMap(arr => arr->Array.get(0))
  ->Option.flatMap(JSON.Decode.object)
  ->Option.flatMap(dict => dict->Dict.get("name"))
  ->Option.flatMap(JSON.Decode.string)
  ->Option.map(name => name->String.equal("t"))
  ->Option.getOr(false)
}

let getFieldDeclarations = (json: JSON.t): array<(string, string)> => {
  json
  ->getItemsOpt
  ->Option.map(arrJson =>
    arrJson->Array.flatMap(json' => {
      json'
      ->JSON.Decode.object
      ->Option.flatMap(dict => dict->Dict.get("detail"))
      ->Option.flatMap(JSON.Decode.object)
      ->Option.flatMap(dict => dict->Dict.get("items"))
      ->Option.flatMap(JSON.Decode.array)
      ->Option.map(
        fieldsArray =>
          fieldsArray->Array.filterMap(
            fieldJson => {
              fieldJson
              ->JSON.Decode.object
              ->Option.flatMap(
                fieldDict => {
                  let name = fieldDict->Dict.get("name")->Option.flatMap(JSON.Decode.string)
                  let signature =
                    fieldDict->Dict.get("signature")->Option.flatMap(JSON.Decode.string)

                  switch (name, signature) {
                  | (Some(n), Some(s)) => Some((n, s))
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
