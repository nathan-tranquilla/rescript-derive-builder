open Mocha
open Test_utils
open NodeJs

test("Test that generated source code compiles", () => {
  // Change to tests directory
  let process = Process.process
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

    // Check that the compiled JavaScript file exists
    let compiledFileExists = switch Fs.readdirSync("../lib/es6/tests/__generated__") {
    | files => files->Array.some(file =>
        file->String.includes("TestTypeBuilder") && file->String.endsWith(".mjs")
      )
    | exception _ => false
    }

    if !compiledFileExists {
      fail("Generated code did not compile - TestTypeBuilder.res.mjs not found")
    }

    Stdlib.Console.log("Integration test passed - generated code compiles successfully")

    // Always restore original directory
    Process.chdir(process, originalCwd)
  } catch {
  | JsExn(exn) => {
      // Always restore original directory on error
      Process.chdir(process, originalCwd)
      fail(`Integration test failed: ${exn->JsExn.message->Option.getOr("Unknown")}`)
    }
  }
})
