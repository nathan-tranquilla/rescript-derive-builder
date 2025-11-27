open Mocha
open Test_utils
open BuilderMetadata

test("getStringArray", () => {
  switch `["test","test","test"]`
  ->JSON.parseOrThrow
  ->getStringArray {
  | None => fail("getStringArray: failed to parse JSON string")
  | Some(arrStr) =>
    eq(
      "getStringArray correctly parsed JSON array to string array",
      arrStr,
      ["test", "test", "test"],
    )
  }
})

test("getObjectArray", () => {
  switch `[{"name": "test1"}, {"name": "test2"}]`
  ->JSON.parseOrThrow
  ->getObjectArray {
  | None => fail("getObjectArray: failed to parse JSON array")
  | Some(arrObj) => {
      let expected = [
        Dict.fromArray([("name", JSON.String("test1"))]),
        Dict.fromArray([("name", JSON.String("test2"))]),
      ]
      eq("getObjectArray correctly parsed JSON array to dict array", arrObj, expected)
    }
  }
})

test("hasBuilderDerivation", () => {
  // Test with array containing builder derivation
  let withBuilder = ["Some other text", "@@deriving(builder) other test", "More text"]
  eq(
    "hasBuilderDerivation detects @@deriving(builder) in array",
    hasBuilderDerivation(withBuilder),
    true,
  )

  // Test with array not containing builder derivation
  let withoutBuilder = ["Some text", "@@deriving(show)", "Other derivations"]
  eq(
    "hasBuilderDerivation returns false when no @@deriving(builder) present",
    hasBuilderDerivation(withoutBuilder),
    false,
  )

  // Test with empty array
  let empty = []
  eq("hasBuilderDerivation returns false for empty array", hasBuilderDerivation(empty), false)
})

test("checkItemForBuilder", () => {
  // Test item with builder derivation
  let itemWithBuilder = Dict.fromArray([
    ("docstrings", JSON.Array([JSON.String("@@deriving(builder)")])),
  ])
  eq(
    "checkItemForBuilder integrates docstring extraction and builder detection",
    checkItemForBuilder(itemWithBuilder),
    true,
  )

  // Test item without docstrings field
  let itemNoDocstrings = Dict.fromArray([("name", JSON.String("SomeType"))])
  eq(
    "checkItemForBuilder handles missing docstrings field",
    checkItemForBuilder(itemNoDocstrings),
    false,
  )
})

test("getFileName", () => {
  // Test valid JSON with name field
  let validJson = JSON.Object(Dict.fromArray([("name", JSON.String("UserType"))]))
  eq("getFileName extracts name from valid JSON object", getFileName(validJson), Ok("UserType"))

  // Test JSON without name field
  let noNameJson = JSON.Object(Dict.fromArray([("other", JSON.String("value"))]))
  eq(
    "getFileName returns error when name field missing",
    getFileName(noNameJson),
    Error("No 'name' found"),
  )

  // Test non-object JSON
  let nonObjectJson = JSON.String("not an object")
  eq(
    "getFileName handles non-object JSON gracefully",
    getFileName(nonObjectJson),
    Error("No 'name' found"),
  )
})

test("getItemsOpt", () => {
  // Test valid JSON with items field
  let validJson = JSON.Object(
    Dict.fromArray([("items", JSON.Array([JSON.String("item1"), JSON.String("item2")]))]),
  )
  eq(
    "getItemsOpt extracts items array from valid JSON object",
    getItemsOpt(validJson),
    Some([JSON.String("item1"), JSON.String("item2")]),
  )

  // Test JSON without items field
  let noItemsJson = JSON.Object(Dict.fromArray([("name", JSON.String("SomeType"))]))
  eq("getItemsOpt returns None when items field missing", getItemsOpt(noItemsJson), None)

  // Test non-object JSON
  let nonObjectJson = JSON.String("not an object")
  eq("getItemsOpt handles non-object JSON gracefully", getItemsOpt(nonObjectJson), None)

  // Test items field with non-array value
  let nonArrayItemsJson = JSON.Object(Dict.fromArray([("items", JSON.String("not an array"))]))
  eq(
    "getItemsOpt returns None when items field is not an array",
    getItemsOpt(nonArrayItemsJson),
    None,
  )
})

test("isADotTType", () => {
  // Test JSON with first item having name "t"
  let dotTTypeJson = JSON.Object(
    Dict.fromArray([
      (
        "items",
        JSON.Array([
          JSON.Object(Dict.fromArray([("name", JSON.String("t"))])),
          JSON.Object(Dict.fromArray([("name", JSON.String("other"))])),
        ]),
      ),
    ]),
  )
  eq("isADotTType returns true when first item has name 't'", isADotTType(dotTTypeJson), true)

  // Test JSON with first item NOT having name "t"
  let nonDotTTypeJson = JSON.Object(
    Dict.fromArray([
      (
        "items",
        JSON.Array([
          JSON.Object(Dict.fromArray([("name", JSON.String("user"))])),
          JSON.Object(Dict.fromArray([("name", JSON.String("t"))])),
        ]),
      ),
    ]),
  )
  eq(
    "isADotTType returns false when first item name is not 't'",
    isADotTType(nonDotTTypeJson),
    false,
  )

  // Test JSON with no items (relies on getItemsOpt)
  let noItemsJson = JSON.Object(Dict.fromArray([("name", JSON.String("SomeType"))]))
  eq("isADotTType returns false when no items present", isADotTType(noItemsJson), false)

  // Test JSON with empty items array
  let emptyItemsJson = JSON.Object(Dict.fromArray([("items", JSON.Array([]))]))
  eq("isADotTType returns false when items array is empty", isADotTType(emptyItemsJson), false)
})

test("getFieldDeclarations", () => {
  // Test JSON with valid field declarations
  let validFieldsJson = JSON.Object(
    Dict.fromArray([
      (
        "items",
        JSON.Array([
          JSON.Object(
            Dict.fromArray([
              (
                "detail",
                JSON.Object(
                  Dict.fromArray([
                    (
                      "items",
                      JSON.Array([
                        JSON.Object(
                          Dict.fromArray([
                            ("name", JSON.String("username")),
                            ("signature", JSON.String("string")),
                            ("optional", JSON.Boolean(false)),
                          ]),
                        ),
                        JSON.Object(
                          Dict.fromArray([
                            ("name", JSON.String("age")),
                            ("signature", JSON.String("int")),
                            ("optional", JSON.Boolean(false)),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]),
  )
  eq(
    "getFieldDeclarations extracts name-signature pairs from valid structure",
    getFieldDeclarations(validFieldsJson),
    [("username", "string", false), ("age", "int", false)],
  )

  // Test JSON with incomplete field (missing signature)
  let incompleteFieldJson = JSON.Object(
    Dict.fromArray([
      (
        "items",
        JSON.Array([
          JSON.Object(
            Dict.fromArray([
              (
                "detail",
                JSON.Object(
                  Dict.fromArray([
                    (
                      "items",
                      JSON.Array([
                        JSON.Object(
                          Dict.fromArray([
                            ("name", JSON.String("username")),
                            // Missing signature
                          ]),
                        ),
                        JSON.Object(
                          Dict.fromArray([
                            ("name", JSON.String("age")),
                            ("signature", JSON.String("int")),
                            ("optional", JSON.Boolean(false)),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]),
  )
  eq(
    "getFieldDeclarations skips incomplete fields and returns valid ones",
    getFieldDeclarations(incompleteFieldJson),
    [("age", "int", false)],
  )

  // Test JSON with no items (leverages getItemsOpt)
  let noItemsJson = JSON.Object(Dict.fromArray([("name", JSON.String("SomeType"))]))
  eq(
    "getFieldDeclarations returns empty array when no items",
    getFieldDeclarations(noItemsJson),
    [],
  )

  // Test JSON with empty structure
  let emptyStructureJson = JSON.Object(Dict.fromArray([("items", JSON.Array([]))]))
  eq(
    "getFieldDeclarations returns empty array for empty items",
    getFieldDeclarations(emptyStructureJson),
    [],
  )
})
