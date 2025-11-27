# ReScript Derive Builder

A ReScript library that automatically generates builder patterns for your types using docstring annotations.

## Overview

This library searches for a `rescript.json` file containing "derive-builder" configuration and generates fluent builder code for ReScript types annotated with `@@deriving(builder)` in their docstrings. It traverses up the directory tree to find the configuration and processes all matching source files.

The library uses the `rescript-tools doc` command internally to extract type information and docstrings from your ReScript source files, then processes this data to generate builder patterns.

## Quick Start

1. **Install**: `npm install rescript-derive-builder` (requires ReScript >= 12.0.0)
2. **Configure**: Add to your `rescript.json`:
   ```json
   {
     "derive-builder": {
       "include": ["src/**/*.res"],
       "output": "src/generated"
     }
   }
   ```
3. **Annotate**: Add `@@deriving(builder)` to your type's docstring
4. **Generate**: Run `npx rescript-derive-builder`
5. **Use**: Import and use your generated builder!

## Installation

**Requirements:**
- ReScript >= 12.0.0

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
 * @@deriving(builder)
 * 
 * User type with builder pattern support.
 * Other documentation can be present too.
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
let user = UserBuilder.empty()
  ->UserBuilder.name("John Doe")
  ->UserBuilder.age(25)
  ->UserBuilder.email(Some("john@example.com"))
  ->UserBuilder.build()

switch user {
| Ok(validUser) => Stdlib.Console.log("Created user successfully")
| Error(message) => Js.Console.error(`Builder error: ${message}`)
}
```

## Features

- **Optional Field Support**: Supports ReScript's optional field syntax (`name?: string`)
- **Comprehensive Error Messages**: Specific error messages for each missing required field
- **Automatic Discovery**: Finds `rescript.json` with derive-builder config
- **Glob Pattern Support**: Flexible file matching with glob patterns
- **Builder Pattern Generation**: Creates fluent, type-safe builders with validation
- **Error Handling**: Comprehensive error messages for configuration issues
- **Chain of Command**: Extensible code generation strategies

## Current Limitations & Extensibility

### Supported Type Patterns

Currently, this library only supports the **main type pattern** - types named `t` that are the primary type in a ReScript module:

```rescript
// ✅ Supported: Main module type named 't'
/**
 * @@deriving(builder)
 */
type t = {
  name: string,
  age: int,
}
```

```rescript
// ❌ Not yet supported: Named types other than 't'
/**
 * @@deriving(builder) 
 */
type user = {
  name: string,
  age: int,
}

// ❌ Not yet supported: Variant types
/**
 * @@deriving(builder)
 */
type shape = Circle(float) | Rectangle(float, float)
```

### Extensibility by Design

The library is architected with a **strategy pattern** that makes adding support for new type patterns straightforward:

- **`HandlerInterface`**: Defines the contract for new type handlers
- **Chain of Command**: Handlers are linked together, trying each in sequence
- **Modular Handlers**: Each type pattern has its own dedicated handler module

**Adding new type support** requires:
1. Creating a new handler module implementing `HandlerInterface`
2. Adding it to the handler chain in `CodegenStrategyCoordinator`

This design ensures the library can easily grow to support:
- Named record types (`type user = {...}`)
- Variant types with constructors
- Tuple types
- Nested type definitions
- Custom type patterns

The current limitation is intentional - we're starting with the most common ReScript pattern (`.t` types) and will expand based on community needs.

## Optional Fields

You can mark fields as optional using ReScript's optional syntax:

```rescript
/**
 * @@deriving(builder)
 */
type user = {
  name: string,        // Required field
  age: int,           // Required field  
  email?: string,     // Optional field
  phone?: string,     // Optional field
}
```

Optional fields:
- Don't need to be set in the builder
- Won't generate "missing field" errors
- Are automatically typed as `option<T>` in the final record

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

- **`ConfigDiscovery`**: Finds and parses derive-builder configuration with detailed error messages
- **`BuilderMetadata`**: Parses ReScript documentation JSON for type information (from `rescript-tools doc` output), extracts field declarations with optional field detection
- **`CodegenStrategy`**: Chain of command pattern for code generation strategies, supports different type patterns (currently `.t` types)
- **`Codegen`**: Main coordination module that executes `rescript-tools doc` and orchestrates the generation process

### Generated Builder Structure

For each type, the generator creates:
- **Builder type**: Internal state tracking with `option<T>` for all fields  
- **`empty()` function**: Creates initial builder state
- **Setter functions**: One per field, with proper type signature based on whether field is optional
- **`build()` function**: Validates required fields and constructs final object using comprehensive pattern matching

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
