open NodeJs

let process = Process.process

let findConfig = (~filename: string, ~startDir=Process.cwd(process), ~maxDepth=5): result<string, string> => {
  Ok("")
}