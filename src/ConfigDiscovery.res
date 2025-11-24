let fileContains = (filePath: string, searchString: string): bool => {
  try {
    open NodeJs
    let content = Fs.readFileSync(filePath)
    content->Buffer.toString->String.includes(searchString)
  } catch {
  | Exn.Error(_) => false
  }
}

module ConfigKeys = {
  let root = "derive-builder"
  let include_ = "include"  // include is a reserved keyword
  let output = "output"
}

let rec findConfig = (
  ~filename="rescript.json",
  ~startDir:string,
  ~maxDepth=10,
): result<string, string> => {
  open NodeJs
  let path = Path.join2(startDir, filename)
  if Fs.existsSync(path) && fileContains(path, ConfigKeys.root) {
    Ok(path)
  } else if maxDepth - 1 >= 0 {
    findConfig(~filename, ~startDir=Path.dirname(startDir), ~maxDepth=maxDepth - 1)
  } else {
    Error(`Could not find ${filename} with "${ConfigKeys.root}" configuration in ${startDir} or any parent directory (searched ${Int.toString(10-maxDepth)} levels up). 

Add this to your ${filename}:
{
  "derive-builder": {
    "include": ["src/**/*.res"],
    "output": "src/generated"
  }
}`)
  }
}

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

// Helper functions
let expandToAbsolute = (basePath: string, filePath: string): string => {
  NodeJs.Path.resolve([basePath, filePath])
}

let extractGlobPatterns = (jsonArray: array<JSON.t>): array<string> =>
  jsonArray->Array.filterMap(glob =>
    switch glob {
    | JSON.String(pattern) => Some(pattern)
    | _ => None
    }
  )

let expandGlobs = (patterns: array<string>, ~cwd: string): array<string> =>
  patterns->Array.flatMap(pattern => globSync(pattern, ~options={cwd, absolute: true}))

type configFile = {
  @as("include") paths: array<string>,
  output: string,
}

let parseConfigContent = (content: string, path: string): result<configFile, string> => {
  let configDir = NodeJs.Path.dirname(path)
  try {

    Console.log("here first")
    let configObj = JSON.parseExn(content)->JSON.Decode.object
      ->Option.flatMap(dict => dict->Dict.get(ConfigKeys.root))
      ->Option.flatMap(json => json->JSON.Decode.object)

    Console.log("here")

    let pathsOpt =
      configObj
      ->Option.flatMap(dict => dict->Dict.get(ConfigKeys.include_))
      ->Option.flatMap(json => json->JSON.Decode.array)
      ->Option.map(globs => globs->extractGlobPatterns->expandGlobs(~cwd=configDir))

    let outputOpt =
      configObj
      ->Option.flatMap(dict => dict->Dict.get(ConfigKeys.output))
      ->Option.flatMap(json => json->JSON.Decode.string)
      ->Option.map(output => expandToAbsolute(configDir, output))

    switch (pathsOpt, outputOpt) {
    | (Some(paths), Some(output)) =>
      Ok({
        paths,
        output,
      })
    | (None, Some(_)) => Error(`Missing or invalid "include" field in ${path}. Expected an array of glob patterns like: ["src/**/*.res"]`)
    | (Some(_), None) => Error(`Missing or invalid "output" field in ${path}. Expected a string path like: "src/generated"`)
    | (None, None) => Error(`Invalid configuration in ${path}. Missing both "include" and "output" fields. Expected:
{
  "derive-builder": {
    "include": ["src/**/*.res"],
    "output": "src/generated"
  }
}`)
    }
  } catch {
  | Exn.Error(_) => Error(`Invalid JSON syntax in ${path}. Please check that your configuration file contains valid JSON.

Expected format:
{
  "derive-builder": {
    "include": ["src/**/*.res"],
    "output": "src/generated"
  }
}`)
  }
}

let getConfigContent = (~process: NodeJs.Process.t): result<configFile, string> => {
  switch findConfig(~startDir=NodeJs.Process.cwd(process)) {
  | Ok(path) => {
      let content =
        NodeJs.Fs.readFileSync(path)->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      parseConfigContent(content, path)
    }
  | Error(msg) => Error(msg)
  }
}
