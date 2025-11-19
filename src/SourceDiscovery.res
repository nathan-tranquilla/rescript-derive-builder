// Glob options type
type globOptions = {
  cwd?: string,
  dot?: bool,
  absolute?: bool,
  ignore?: array<string>,
  nodir?: bool,
  maxDepth?: int,
}

@module("glob") external globSync: (string, ~options: globOptions=?) => array<string> = "globSync"

// Constants
let configErrorMsg = "must be a JSON object with the following keys: 'include', 'exclude', and 'output'"

let expandGlobs = (patterns: array<string>, ~cwd: string): array<string> =>
  patterns->Array.flatMap(pattern => globSync(pattern, ~options={cwd: cwd, absolute: true}))

// GraphQL-style field extractors
let getObjectField = (obj: Js.Dict.t<JSON.t>, field: string): option<JSON.t> =>
  obj->Dict.get(field)

let getStringArray = (json: JSON.t): option<array<string>> =>
  json
  ->Js.Json.decodeArray
  ->Option.map(arr =>
    arr->Array.filterMap(item =>
      item->Js.Json.decodeString
    )
  )

let parseConfigContent = (content: string, path: string): result<array<string>, string> => {
  let configDir = NodeJs.Path.dirname(path)
  
  try {
    content
    ->JSON.parseExn
    ->Js.Json.decodeObject
    ->Option.flatMap(obj =>
      obj
      ->getObjectField("include")
      ->Option.flatMap(getStringArray)
      ->Option.map(patterns => patterns->expandGlobs(~cwd=configDir))
    )
    ->Option.map(files => Ok(files))
    ->Option.getOr(Error(`${path} ${configErrorMsg}`))
  } catch {
  | Exn.Error(_) => Error(`error parsing ${path}`)
  }
}

let getSourceFiles = (~process: NodeJs.Process.t): result<array<string>, string> => {
  switch ConfigDiscovery.findConfig(~startDir=NodeJs.Process.cwd(process)) {
  | Ok(path) => {
      let content = NodeJs.Fs.readFileSync(path)->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      parseConfigContent(content, path)
    }
  | Error(msg) => Error(msg)
  }
}
