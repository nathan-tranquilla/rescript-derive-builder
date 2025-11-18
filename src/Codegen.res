@module("glob") external globSync: string => array<string> = "globSync"

let getSourceFiles = (~process: NodeJs.Process.t): result<array<string>, string> => {
  switch ConfigDiscovery.findConfig(~startDir=NodeJs.Process.cwd(process)) {
  | Ok(path) => {
      let content =
        NodeJs.Fs.readFileSync(path)->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      try {
        switch JSON.parseExn(content) {
        | Object(dict) =>
          switch dict->Dict.get("include") {
          | None =>
            Error(
              `${path} must be a JSON object with the following keys: 'include', 'exclude', and 'output'`,
            )
          | Some(includes) =>
            switch includes {
            | JSON.Array(globs) =>
              Ok(
                globs
                ->Array.filterMap(glob =>
                  switch glob {
                  | JSON.String(globPath) => Some(globPath)
                  | _ => None
                  }
                )
                ->Array.reduce([], (resolvedPaths, globPath) =>
                  resolvedPaths->Belt.Array.concat(globSync(globPath))
                ),
              )
            | _ => Error(`'includes' must be an array of globs`)
            }
          }
        | _ =>
          Error(
            `${path} must be a JSON object with the following keys: 'include', 'exclude', and 'output'`,
          )
        }
      } catch {
      | Exn.Error(_) => Error(`error parsing ${path}`)
      }
    }
  | Error(msg) => Error(msg)
  }
}

let process = NodeJs.Process.process
switch getSourceFiles(~process) {
| Ok(sourceFiles) => {
    Js.Console.log(sourceFiles)
    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Js.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
