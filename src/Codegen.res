
let process = NodeJs.Process.process
switch SourceDiscovery.getSourceFiles(~process) {
| Ok(sourceFiles) => {
    Js.Console.log(sourceFiles)
    NodeJs.Process.exit(process, ())
  }
| Error(msg) => {
    Js.Console.log(msg)
    NodeJs.Process.exitWithCode(process, 1)
  }
}
