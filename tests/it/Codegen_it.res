open Test
open NodeJs

test("Test that generated source code compiles", () => {
  // Change to tests directory
  let process=Process.process
  let originalCwd = Process.cwd(process)
  Process.chdir(process, "./tests")
  
  try {
    // Ensure __generated__ directory exists
    if !Fs.existsSync("__generated__") {
      Fs.mkdirSync("__generated__")
    }
    
    // First, just build the fixtures (this should work)
    let _ = ChildProcess.execSync("npx rescript")
    
    // Run code generation from tests directory - this creates the builder files
    let _ = ChildProcess.execSync("node ../bin/cli.js")
    
    // Update rescript.json to include __generated__ directory
    let configContent = Fs.readFileSync("rescript.json")->Buffer.toString
    let updatedConfig = configContent->String.replace(
      `"sources": [ 
    {
      "dir": "__fixtures__",
      "subdirs": false
    }
  ],`,
      `"sources": [ 
    {
      "dir": "__fixtures__",
      "subdirs": false
    },
    {
      "dir": "__generated__",
      "subdirs": false
    }
  ],`
    )
    Fs.writeFileSync("rescript.json", Buffer.fromString(updatedConfig))
    
    // Now rebuild to ensure generated code compiles
    let _ = ChildProcess.execSync("npx rescript")
    
    Js.Console.log("Integration test passed - generated code compiles successfully")
    
    // Always restore original directory
    Process.chdir(process, originalCwd)
  } catch {
  | Exn.Error(err) => {
      // Always restore original directory on error
      Process.chdir(process,originalCwd)
      Js.Console.error(`Integration test failed: ${Exn.message(err)->Option.getOr("Unknown")}`)
      fail()
    }
  }
})
