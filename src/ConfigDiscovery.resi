let findConfig: (~filename: string=?, ~startDir: string, ~maxDepth: int=?) => result<string, string>

type configFile = {
  @as("include") paths: array<string>,
  output: string,
}

let getConfigContent: (~process: NodeJs.Process.t) => result<configFile, string>
