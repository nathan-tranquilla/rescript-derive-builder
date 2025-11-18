let process = NodeJs.Process.process

let rec findConfig = (~filename: string, ~startDir=NodeJs.Process.cwd(process), ~maxDepth=10): result<string, string> => {
  open NodeJs
  let path = Path.join2(startDir, filename)
  if Fs.existsSync(path) {
    Ok(path)
  } else {
    if maxDepth-1 > 0 {
      findConfig(~filename=filename, ~startDir=Path.dirname(startDir), ~maxDepth=maxDepth-1)
    } else {
      Error(`Could not find file ${filename}`)
    }
    
  }
}
