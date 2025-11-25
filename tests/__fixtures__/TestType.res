/**
 @@deriving(builder)
 
 A comprehensive type with all ReScript primitives for testing
 */
type t = {
  // Basic primitives
  stringField: string,
  intField: int,
  floatField: float,
  boolField: bool,
  unitField: unit,
  
  // Optional types
  optionalString: option<string>,
  optionalInt: option<int>,
  optionalFloat: option<float>,
  optionalBool: option<bool>,
  
  // Array types
  stringArray: array<string>,
  intArray: array<int>,
  floatArray: array<float>,
  boolArray: array<bool>,
  
  // Other common types
  jsonField: JSON.t,
  resultField: result<string, string>,
  promiseField: promise<string>,
  
  // Nested options and arrays
  optionalStringArray: option<array<string>>,
  arrayOfOptionalStrings: array<option<string>>,
  
  // Complex nested types
  nestedResult: result<option<string>, array<string>>,
  complexOptional: option<result<array<int>, string>>,
}