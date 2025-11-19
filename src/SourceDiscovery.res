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

// Helper functions
let extractGlobPatterns = (jsonArray: array<JSON.t>): array<string> =>
  jsonArray->Array.filterMap(glob =>
    switch glob {
    | JSON.String(pattern) => Some(pattern)
    | _ => None
    }
  )

let expandGlobs = (patterns: array<string>, ~cwd: string): array<string> =>
  patterns->Array.flatMap(pattern => globSync(pattern, ~options={cwd, absolute: true}))

let parseConfigContent = (content: string, path: string): result<array<string>, string> => {
  let configDir = NodeJs.Path.dirname(path)
  try {
    switch JSON.parseExn(content) {
    | Object(dict) =>
      switch dict->Dict.get("include") {
      | None => Error(`${path} ${configErrorMsg}`)
      | Some(includes) =>
        switch includes {
        | JSON.Array(globs) => Ok(globs->extractGlobPatterns->expandGlobs(~cwd=configDir))
        | _ => Error(`'includes' must be an array of globs`)
        }
      }
    | _ => Error(`${path} ${configErrorMsg}`)
    }
  } catch {
  | Exn.Error(_) => Error(`error parsing ${path}`)
  }
}

let getSourceFiles = (~process: NodeJs.Process.t): result<array<string>, string> => {
  switch ConfigDiscovery.findConfig(~startDir=NodeJs.Process.cwd(process)) {
  | Ok(path) => {
      let content =
        NodeJs.Fs.readFileSync(path)->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      parseConfigContent(content, path)
    }
  | Error(msg) => Error(msg)
  }
}
