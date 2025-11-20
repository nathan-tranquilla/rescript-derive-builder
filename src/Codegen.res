open NodeJs

let filterBuilders = (~filename: string, ~content: string): option<(string, string)> => {
  try {
    content
    ->JSON.parseExn
    ->JSON.Decode.object
    ->Option.flatMap(dict =>
      dict
      ->Dict.get("items")
      ->Option.flatMap(BuilderMetadata.getObjectArray)
      ->Option.map(items =>
        items->Array.some(BuilderMetadata.checkItemForBuilder) ? Some((filename, content)) : None
      )
      ->Option.getOr(None)
    )
  } catch {
  | Exn.Error(_) => None
  }
}

let process = NodeJs.Process.process
switch ConfigDiscovery.getConfigContent(~process) {
| Ok(cfgFile) => {
    let sourceFiles = cfgFile.paths
    sourceFiles
    ->Array.filterMap(sourceFile => {
      let output =
        ChildProcess.execSync(
          `npx rescript-tools doc ${sourceFile}`,
        )->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      filterBuilders(~filename=sourceFile, ~content=output)
    })
    ->Array.forEach(((filename, content)) => {
      try {
        open CodegenStrategy
        let jsonDoc = JSON.parseExn(content)
        let code = CodegenStrategyCoordinator.exec(jsonDoc)->Result.getExn
        let outputFilename = Path.join2(cfgFile.output, Path.parse(filename).name ++ "Builder.res")
        Fs.mkdirSyncWith(cfgFile.output, {recursive: true})
        Fs.writeFileSync(outputFilename, code->Buffer.fromString)
      } catch {
      | Js.Exn.Error(obj) =>
        switch Js.Exn.message(obj) {
        | Some(msg) if String.includes(msg, "JSON") => Js.Console.log(`JSON parsing error: ${msg}`)
        | Some(msg) if String.includes(msg, "ENOENT") => Js.Console.log(`File not found: ${msg}`)
        | Some(msg) if String.includes(msg, "EACCES") => Js.Console.log(`Permission denied: ${msg}`)
        | Some(msg) if String.includes(msg, "EEXIST") =>
          Js.Console.log(`File already exists: ${msg}`)
        | Some(msg) => Js.Console.log(`Error: ${msg}`)
        | None => Js.Console.log("Unknown error occurred during code generation")
        }
      | Exn.Error(obj) =>
        switch Exn.message(obj) {
        | Some(msg) => Js.Console.log(`System error: ${msg}`)
        | None => Js.Console.log("Unable to produce code - unknown system error")
        }
      }
    })

    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Js.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
