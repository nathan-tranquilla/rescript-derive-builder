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

Stdlib.Console.log("rescript-derive-builder: Starting code generation...")

switch ConfigDiscovery.getConfigContent(~process) {
| Ok(cfgFile) => {
    Stdlib.Console.log(
      `rescript-derive-builder: Found config with ${Array.length(
          cfgFile.paths,
        )->Int.toString} source files`,
    )
    Stdlib.Console.log(`rescript-derive-builder: Output directory: ${cfgFile.output}`)

    let sourceFiles = cfgFile.paths
    let processedFiles = sourceFiles->Array.filterMap(sourceFile => {
      Stdlib.Console.log(`rescript-derive-builder: Processing ${sourceFile}`)
      try {
        let output =
          ChildProcess.execSync(
            `npx rescript-tools doc ${sourceFile}`,
          )->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
        filterBuilders(~filename=sourceFile, ~content=output)
      } catch {
      | JsExn(exn) => {
          Stdlib.Console.error(
            `rescript-derive-builder: Failed to process ${sourceFile}: ${exn
              ->JsExn.message
              ->Option.getOr("Unknown error")}`,
          )
          None
        }
      }
    })

    Stdlib.Console.log(
      `rescript-derive-builder: Found ${Array.length(
          processedFiles,
        )->Int.toString} files with @@deriving(builder)`,
    )

    processedFiles->Array.forEach(((filename, content)) => {
      try {
        open CodegenStrategy
        let jsonDoc = JSON.parseOrThrow(content)
        let code = CodegenStrategyCoordinator.exec(jsonDoc)->Result.getOrThrow
        let outputFilename = Path.join2(cfgFile.output, Path.parse(filename).name ++ "Builder.res")
        Fs.mkdirSyncWith(cfgFile.output, {recursive: true})
        Fs.writeFileSync(outputFilename, code->Buffer.fromString)
        Stdlib.Console.log(`rescript-derive-builder: Generated ${outputFilename}`)
      } catch {
      | JsExn(exn) =>
        switch exn->JsExn.message {
        | Some(msg) => Stdlib.Console.error(`rescript-derive-builder: System error: ${msg}`)
        | None =>
          Stdlib.Console.error(
            "rescript-derive-builder: Unable to produce code - unknown system error",
          )
        }
      }
    })

    Stdlib.Console.log("rescript-derive-builder: Code generation completed")
    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Stdlib.Console.error(`rescript-derive-builder: ${msg}`)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
