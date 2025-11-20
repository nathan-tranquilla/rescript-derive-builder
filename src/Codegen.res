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
switch SourceDiscovery.getSourceFiles(~process) {
| Ok(sourceFiles) => {
    sourceFiles
    ->Array.filterMap(sourceFile => {
      let output =
        ChildProcess.execSync(
          `npx rescript-tools doc ${sourceFile}`,
        )->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.utf8)
      filterBuilders(~filename=sourceFile, ~content=output)
    })
    ->Array.forEach(((_, content)) => {
      try {
        open CodegenStrategy
        let code = CodegenStrategyCoordinator.exec(JSON.parseExn(content))
        ->Result.getExn
        Js.Console.log(code);
      } catch {
        | Exn.Error(_) => Js.Console.log("unable to produce code")
      }
      
    })

    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Js.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
