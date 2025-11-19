
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

let filterBuilders = (~filename: string, ~content: string): option<string> => {
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
          ? Some(filename)
          : None
      )
      ->Option.getOr(None)
    )
  } catch {
  | Exn.Error(_) => None
  }
}

let process = NodeJs.Process.process
switch SourceDiscovery.getSourceFiles(~process) {
| Ok(sourceFiles) => {
    Js.Console.log(sourceFiles)
    let sourceFilesWithBuilder = sourceFiles->Array.filterMap(sourceFile => {
      let output = ChildProcess.execSync(`npx rescript-tools doc ${sourceFile}`)
        ->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      // Js.Console.log(output)
      filterBuilders(~filename=sourceFile, ~content=output)
    }) 
    Js.Console.log(sourceFilesWithBuilder)
    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Js.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
