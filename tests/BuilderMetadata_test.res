open Test
open BuilderMetadata

let intEqual = (~message=?, a: int, b: int) =>
  assertion(~message?, ~operator="intEqual", (a, b) => a === b, a, b)

test("getStringArray", () => {
  switch `["test","test","test"]`
  ->JSON.parseExn
  ->getStringArray {
  | None => fail(~message="getStringArray: failed to parse JSON string", ())
  | Some(arrStr) => assertion(
      ~message="getStringArray correctly parsed JSON array to string array",
      (actual, expected) => actual == expected,
      arrStr,
      ["test", "test", "test"],
    )
  }
})

test("getObjectArray", () => {
  switch `[{"name": "test1"}, {"name": "test2"}]`
  ->JSON.parseExn
  ->getObjectArray {
  | None => fail(~message="getObjectArray: failed to parse JSON array", ())
  | Some(arrObj) => {
      let expected = [
        Dict.fromArray([("name", JSON.String("test1"))]),
        Dict.fromArray([("name", JSON.String("test2"))]),
      ]
      assertion(
        ~message="getObjectArray correctly parsed JSON array to dict array",
        (actual, expected) => actual == expected,
        arrObj,
        expected,
      )
    }
  }
})

test("hasBuilderDerivation", () => {
  // Test with array containing builder derivation
  let withBuilder = ["Some other text", "@@deriving(builder) other test", "More text"]
  assertion(
    ~message="hasBuilderDerivation detects @@deriving(builder) in array",
    (actual, expected) => actual == expected,
    hasBuilderDerivation(withBuilder),
    true,
  )

  // Test with array not containing builder derivation
  let withoutBuilder = ["Some text", "@@deriving(show)", "Other derivations"]
  assertion(
    ~message="hasBuilderDerivation returns false when no @@deriving(builder) present",
    (actual, expected) => actual == expected,
    hasBuilderDerivation(withoutBuilder),
    false,
  )

  // Test with empty array
  let empty = []
  assertion(
    ~message="hasBuilderDerivation returns false for empty array",
    (actual, expected) => actual == expected,
    hasBuilderDerivation(empty),
    false,
  )
})

test("checkItemForBuilder", () => {
  // Test item with builder derivation
  let itemWithBuilder = Dict.fromArray([
    ("docstrings", JSON.Array([JSON.String("@@deriving(builder)")]))
  ])
  assertion(
    ~message="checkItemForBuilder integrates docstring extraction and builder detection",
    (actual, expected) => actual == expected,
    checkItemForBuilder(itemWithBuilder),
    true,
  )

  // Test item without docstrings field
  let itemNoDocstrings = Dict.fromArray([("name", JSON.String("SomeType"))])
  assertion(
    ~message="checkItemForBuilder handles missing docstrings field",
    (actual, expected) => actual == expected,
    checkItemForBuilder(itemNoDocstrings),
    false,
  )
})

test("getFileName", () => {
  // Test valid JSON with name field
  let validJson = JSON.Object(Dict.fromArray([
    ("name", JSON.String("UserType"))
  ]))
  assertion(
    ~message="getFileName extracts name from valid JSON object",
    (actual, expected) => actual == expected,
    getFileName(validJson),
    Ok("UserType"),
  )

  // Test JSON without name field
  let noNameJson = JSON.Object(Dict.fromArray([
    ("other", JSON.String("value"))
  ]))
  assertion(
    ~message="getFileName returns error when name field missing",
    (actual, expected) => actual == expected,
    getFileName(noNameJson),
    Error("No 'name' found"),
  )

  // Test non-object JSON
  let nonObjectJson = JSON.String("not an object")
  assertion(
    ~message="getFileName handles non-object JSON gracefully",
    (actual, expected) => actual == expected,
    getFileName(nonObjectJson),
    Error("No 'name' found"),
  )
})

test("getItemsOpt", () => {
  // Test valid JSON with items field
  let validJson = JSON.Object(Dict.fromArray([
    ("items", JSON.Array([
      JSON.String("item1"),
      JSON.String("item2")
    ]))
  ]))
  assertion(
    ~message="getItemsOpt extracts items array from valid JSON object",
    (actual, expected) => actual == expected,
    getItemsOpt(validJson),
    Some([JSON.String("item1"), JSON.String("item2")]),
  )

  // Test JSON without items field
  let noItemsJson = JSON.Object(Dict.fromArray([
    ("name", JSON.String("SomeType"))
  ]))
  assertion(
    ~message="getItemsOpt returns None when items field missing",
    (actual, expected) => actual == expected,
    getItemsOpt(noItemsJson),
    None,
  )

  // Test non-object JSON
  let nonObjectJson = JSON.String("not an object")
  assertion(
    ~message="getItemsOpt handles non-object JSON gracefully",
    (actual, expected) => actual == expected,
    getItemsOpt(nonObjectJson),
    None,
  )

  // Test items field with non-array value
  let nonArrayItemsJson = JSON.Object(Dict.fromArray([
    ("items", JSON.String("not an array"))
  ]))
  assertion(
    ~message="getItemsOpt returns None when items field is not an array",
    (actual, expected) => actual == expected,
    getItemsOpt(nonArrayItemsJson),
    None,
  )
})

test("isADotTType", () => {
  // Test JSON with first item having name "t" 
  let dotTTypeJson = JSON.Object(Dict.fromArray([
    ("items", JSON.Array([
      JSON.Object(Dict.fromArray([("name", JSON.String("t"))])),
      JSON.Object(Dict.fromArray([("name", JSON.String("other"))]))
    ]))
  ]))
  assertion(
    ~message="isADotTType returns true when first item has name 't'",
    (actual, expected) => actual == expected,
    isADotTType(dotTTypeJson),
    true,
  )

  // Test JSON with first item NOT having name "t"
  let nonDotTTypeJson = JSON.Object(Dict.fromArray([
    ("items", JSON.Array([
      JSON.Object(Dict.fromArray([("name", JSON.String("user"))])),
      JSON.Object(Dict.fromArray([("name", JSON.String("t"))]))
    ]))
  ]))
  assertion(
    ~message="isADotTType returns false when first item name is not 't'",
    (actual, expected) => actual == expected,
    isADotTType(nonDotTTypeJson),
    false,
  )

  // Test JSON with no items (relies on getItemsOpt)
  let noItemsJson = JSON.Object(Dict.fromArray([("name", JSON.String("SomeType"))]))
  assertion(
    ~message="isADotTType returns false when no items present",
    (actual, expected) => actual == expected,
    isADotTType(noItemsJson),
    false,
  )

  // Test JSON with empty items array
  let emptyItemsJson = JSON.Object(Dict.fromArray([("items", JSON.Array([]))]))
  assertion(
    ~message="isADotTType returns false when items array is empty",
    (actual, expected) => actual == expected,
    isADotTType(emptyItemsJson),
    false,
  )
})

test("getFieldDeclarations", () => {
  // Test JSON with valid field declarations
  let validFieldsJson = JSON.Object(Dict.fromArray([
    ("items", JSON.Array([
      JSON.Object(Dict.fromArray([
        ("detail", JSON.Object(Dict.fromArray([
          ("items", JSON.Array([
            JSON.Object(Dict.fromArray([
              ("name", JSON.String("username")),
              ("signature", JSON.String("string"))
            ])),
            JSON.Object(Dict.fromArray([
              ("name", JSON.String("age")),
              ("signature", JSON.String("int"))
            ]))
          ]))
        ])))
      ]))
    ]))
  ]))
  assertion(
    ~message="getFieldDeclarations extracts name-signature pairs from valid structure",
    (actual, expected) => actual == expected,
    getFieldDeclarations(validFieldsJson),
    [("username", "string"), ("age", "int")],
  )

  // Test JSON with incomplete field (missing signature)
  let incompleteFieldJson = JSON.Object(Dict.fromArray([
    ("items", JSON.Array([
      JSON.Object(Dict.fromArray([
        ("detail", JSON.Object(Dict.fromArray([
          ("items", JSON.Array([
            JSON.Object(Dict.fromArray([
              ("name", JSON.String("username"))
              // Missing signature
            ])),
            JSON.Object(Dict.fromArray([
              ("name", JSON.String("age")),
              ("signature", JSON.String("int"))
            ]))
          ]))
        ])))
      ]))
    ]))
  ]))
  assertion(
    ~message="getFieldDeclarations skips incomplete fields and returns valid ones",
    (actual, expected) => actual == expected,
    getFieldDeclarations(incompleteFieldJson),
    [("age", "int")],
  )

  // Test JSON with no items (leverages getItemsOpt)
  let noItemsJson = JSON.Object(Dict.fromArray([("name", JSON.String("SomeType"))]))
  assertion(
    ~message="getFieldDeclarations returns empty array when no items",
    (actual, expected) => actual == expected,
    getFieldDeclarations(noItemsJson),
    [],
  )

  // Test JSON with empty structure
  let emptyStructureJson = JSON.Object(Dict.fromArray([
    ("items", JSON.Array([]))
  ]))
  assertion(
    ~message="getFieldDeclarations returns empty array for empty items",
    (actual, expected) => actual == expected,
    getFieldDeclarations(emptyStructureJson),
    [],
  )
})
