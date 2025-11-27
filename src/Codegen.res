open NodeJs

let filterBuilders = (~filename: string, ~content: string): option<(string, string)> => {
  try {
    content
    ->JSON.parseOrThrow
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
        let jsonDoc = JSON.parseOrThrow(content)
        let code = CodegenStrategyCoordinator.exec(jsonDoc)->Result.getOrThrow
        let outputFilename = Path.join2(cfgFile.output, Path.parse(filename).name ++ "Builder.res")
        Fs.mkdirSyncWith(cfgFile.output, {recursive: true})
        Fs.writeFileSync(outputFilename, code->Buffer.fromString)
      } catch {
      | JsExn(exn) =>
        switch exn->JsExn.message {
        | Some(msg) => Stdlib.Console.log(`System error: ${msg}`)
        | None => Stdlib.Console.log("Unable to produce code - unknown system error")
        }
      }
    })

    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Stdlib.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
