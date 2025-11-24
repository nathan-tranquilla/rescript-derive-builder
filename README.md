# ReScript Derive Builder

A ReScript library that automatically generates builder patterns for your types using docstring annotations.

## Overview

This library searches for a `rescript.json` file containing "derive-builder" configuration and generates fluent builder code for ReScript types annotated with `@@deriving(builder)` in their docstrings. It traverses up the directory tree to find the configuration and processes all matching source files.

The library uses the `rescript-tools doc` command internally to extract type information and docstrings from your ReScript source files, then processes this data to generate builder patterns.

## Installation

```sh
npm install rescript-derive-builder
```

## Configuration

Add a "derive-builder" section to your `rescript.json` file:

```json
{
  "derive-builder": {
    "include": ["src/**/*.res"],
    "output": "src/generated"
  }
}
```

### Configuration Options

- **`include`**: Array of glob patterns for source files to process
- **`output`**: Directory where generated builder files will be created

## Usage

### 1. Annotate your types

Add the `@@deriving(builder)` annotation in a docstring comment above your type:

```rescript
/**
 @@deriving(builder)
 
 User type with builder pattern support.
 Other documentation can be present too.
 */
type user = {
  name: string,
  age: int,
  email: option<string>,
}
```

### 2. Run the code generator

```sh
npx rescript-derive-builder
```

### 3. Use the generated builder

```rescript
let user = UserBuilder.make()
  ->UserBuilder.name("John Doe")
  ->UserBuilder.age(25)
  ->UserBuilder.email(Some("john@example.com"))
  ->UserBuilder.build()
```

## Features

- **Automatic Discovery**: Finds `rescript.json` with derive-builder config
- **Glob Pattern Support**: Flexible file matching with glob patterns
- **Builder Pattern Generation**: Creates fluent, type-safe builders
- **Error Handling**: Comprehensive error messages for configuration issues
- **Chain of Command**: Extensible code generation strategies

## Development

### Build

- Build: `npm run res:build`
- Clean: `npm run res:clean`
- Build & watch: `npm run res:dev`

### Run locally

```sh
npm run res:build
node lib/es6/src/Codegen.res.mjs
```

### Test the CLI

```sh
npm run res:build
node bin/cli.js
```

## Architecture

The library consists of several key modules:

- **`ConfigDiscovery`**: Finds and parses derive-builder configuration
- **`SourceDiscovery`**: Discovers and filters source files using glob patterns
- **`CodegenStrategy`**: Chain of command pattern for code generation strategies
- **`BuilderMetadata`**: Parses ReScript documentation JSON for type information (from `rescript-tools doc` output)
- **`Codegen`**: Main coordination module that executes `rescript-tools doc` and orchestrates the generation process

## Error Messages

The library provides detailed error messages to help with integration:

- Configuration file discovery issues
- JSON syntax errors
- Missing or invalid configuration fields
- File system permission problems

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT
