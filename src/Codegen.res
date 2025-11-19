
open NodeJs

// GraphQL-style field extractors
let getObjectField = (obj: Js.Dict.t<JSON.t>, field: string): option<JSON.t> =>
  obj->Dict.get(field)

let getStringArray = (json: JSON.t): option<array<string>> =>
  json
  ->JSON.Decode.array
  ->Option.map(arr =>
    arr->Array.filterMap(JSON.Decode.string)
  )

let getObjectArray = (json: JSON.t): option<array<Js.Dict.t<JSON.t>>> =>
  json
  ->JSON.Decode.array
  ->Option.map(arr =>
    arr->Array.filterMap(JSON.Decode.object)
  )

let hasBuilderDerivation = (docstrings: array<string>): bool =>
  docstrings->Array.some(docstring => docstring->String.equal("@@deriving(builder)"))

let checkItemForBuilder = (item: Js.Dict.t<JSON.t>): bool =>
  item
  ->getObjectField("docstrings")
  ->Option.flatMap(getStringArray)
  ->Option.map(hasBuilderDerivation)
  ->Option.getOr(false)

let filterBuilders = (~filename: string, ~content: string): option<(string, string)> => {
  try {
    content
    ->JSON.parseExn
    ->JSON.Decode.object
    ->Option.flatMap(dict =>
      dict
      ->getObjectField("items")
      ->Option.flatMap(getObjectArray)
      ->Option.map(items =>
        items->Array.some(checkItemForBuilder)
          ? Some((filename,content))
          : None
      )
      ->Option.getOr(None)
    )
  } catch {
  | Exn.Error(_) => None
  }
}

let getName = (json: JSON.t): result<string, string> => {
  json->JSON.Decode.object
    ->Option.flatMap(dict => dict->Dict.get("name"))
    ->Option.flatMap(JSON.Decode.string)
    ->Option.mapOr(Error("No 'name' found"), name => Ok(name))
}

let generateBuilderSrc = (~content: string): result<string, string> => {
try {
    let json = content->JSON.parseExn
    let nameResult = getName(json)
    switch (nameResult) {
    | (Ok(name)) => {
      Ok(`${name}Builder`)
    }
    | (_) => Error("Unable to generate source code")
    }
  } catch {
  | Exn.Error(_) => Error("Unable to parse json")
  }
}

let process = NodeJs.Process.process
switch SourceDiscovery.getSourceFiles(~process) {
| Ok(sourceFiles) => {
    sourceFiles->Array.filterMap(sourceFile => {
      let output = ChildProcess.execSync(`npx rescript-tools doc ${sourceFile}`)
        ->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      filterBuilders(~filename=sourceFile, ~content=output)
    })->Array.forEach(((_, content)) => {
      let src = generateBuilderSrc(~content)
      Js.Console.log(src)
    })
  
    
    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Js.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
