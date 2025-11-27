open Mocha
open Test_utils
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
        
    // Now rebuild to ensure generated code compiles
    let _ = ChildProcess.execSync("npx rescript")
    
    Stdlib.Console.log("Integration test passed - generated code compiles successfully")
    
    // Always restore original directory
    Process.chdir(process, originalCwd)
  } catch {
  | JsExn(exn) => {
      // Always restore original directory on error
      Process.chdir(process,originalCwd)
      fail(`Integration test failed: ${exn->JsExn.message->Option.getOr("Unknown")}`)
    }
  }
})
