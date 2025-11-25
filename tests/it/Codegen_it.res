open Test
open NodeJs

let setupConfig = (): unit => {
  try {
    // Backup original config if it exists
    if Fs.existsSync("./rescript.json") {
      Js.Console.log("Backing up existing rescript.json...")
      Fs.renameSync(~from="./rescript.json", ~to_="./rescript.json.tmp")
      Js.Console.log("Backup created successfully")
    } else {
      Js.Console.log("No existing rescript.json found")
    }
    // Copy test config (read + write since copyFileSync isn't available)
    Js.Console.log("Copying test config...")
    let content = Fs.readFileSync("./tests/__fixtures__/rescript.json.fix")
    Fs.writeFileSync("./rescript.json", content)
    Js.Console.log("Test config setup successfully")
  } catch {
  | Exn.Error(err) =>
    Js.Console.error(`Failed to setup config: ${Exn.message(err)->Option.getOr("Unknown")}`)
  }
}

let restoreConfig = (): unit => {
  try {
    // Remove the test config file if it exists
    if Fs.existsSync("./rescript.json") {
      Fs.unlinkSync("./rescript.json")
    }
    // Restore the original config
    Fs.renameSync(~from="./rescript.json.tmp", ~to_="./rescript.json")
    Js.Console.log("Config restored successfully")
  } catch {
  | Exn.Error(err) =>
    Js.Console.error(`Failed to restore config: ${Exn.message(err)->Option.getOr("Unknown")}`)
  }
}

test("Test that generated source code compiles", () => {
  // Overwrites rescript.json at the root of the project
  setupConfig()

  // Rebuilds the project with the builder configuration
  let _ = ChildProcess.execSync("npm run res:build")

  // Runs code generation
  let _ = ChildProcess.execSync("node bin/cli.js")

  // Rebuilds the project to generate builder JavaScript code
  let _ = ChildProcess.execSync("npm run res:build")

  // Restores the config
  restoreConfig()

  // Rebuilds the project with original rescript.json
  let _ = ChildProcess.execSync("npm run res:build")
})
