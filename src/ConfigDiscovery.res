let process = NodeJs.Process.process

let rec findConfig = (
  ~filename="derive-builder.config.json",
  ~startDir=NodeJs.Process.cwd(process),
  ~maxDepth=10,
): result<string, string> => {
  open NodeJs
  let path = Path.join2(startDir, filename)
  if Fs.existsSync(path) {
    Ok(path)
  } else if maxDepth - 1 > 0 {
    findConfig(~filename, ~startDir=Path.dirname(startDir), ~maxDepth=maxDepth - 1)
  } else {
    Error(`Could not find file ${filename}`)
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
    let jsonDict = JSON.parseExn(content)->JSON.Decode.object

    let pathsOpt =
      jsonDict
      ->Option.flatMap(dict => dict->Dict.get("include"))
      ->Option.flatMap(json => json->JSON.Decode.array)
      ->Option.map(globs => globs->extractGlobPatterns->expandGlobs(~cwd=configDir))

    let outputOpt =
      jsonDict
      ->Option.flatMap(dict => dict->Dict.get("output"))
      ->Option.flatMap(json => json->JSON.Decode.string)
      ->Option.map(output => expandToAbsolute(configDir, output))

    switch (pathsOpt, outputOpt) {
    | (Some(paths), Some(output)) =>
      Ok({
        paths,
        output,
      })
    | _ => Error(`error parsing contents of ${path}`)
    }
  } catch {
  | Exn.Error(_) => Error(`error parsing ${path}`)
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
