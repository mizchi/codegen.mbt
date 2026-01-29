///|
/// Rust emitter tests

///|
test "rust: emit basic struct" {
  let user = @ir.Struct::new("User")
    .with_doc("A user in the system")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()))
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))
  let output = RustEmitter::new().emit_struct(user)
  assert_true(output.contains("/// A user in the system"))
  assert_true(
    output.contains("#[derive(Debug, Clone, Serialize, Deserialize)]"),
  )
  assert_true(output.contains("#[serde(rename_all = \"camelCase\")]"))
  assert_true(output.contains("pub struct User"))
  assert_true(output.contains("pub id: i64"))
  assert_true(output.contains("pub name: String"))
  assert_true(output.contains("pub email: Option<String>"))
  assert_true(output.contains("pub tags: Vec<String>"))
}

///|
test "rust: emit simple enum" {
  let status = @ir.Enum::new("Status")
    .with_doc("User account status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
    .with_variant(@ir.Variant::new("Pending"))
  let output = RustEmitter::new().emit_enum(status)
  assert_true(output.contains("/// User account status"))
  assert_true(
    output.contains("#[derive(Debug, Clone, Serialize, Deserialize)]"),
  )
  assert_true(
    output.contains("#[serde(tag = \"type\", rename_all = \"camelCase\")]"),
  )
  assert_true(output.contains("pub enum Status"))
  assert_true(output.contains("Active,"))
  assert_true(output.contains("Inactive,"))
  assert_true(output.contains("Pending,"))
}

///|
test "rust: emit enum with tuple variant" {
  let result = @ir.Enum::new("Result")
    .with_variant(@ir.Variant::new("Ok").with_tuple([@ir.Type::string()]))
    .with_variant(@ir.Variant::new("Err").with_tuple([@ir.Type::string()]))
  let output = RustEmitter::new().emit_enum(result)
  assert_true(output.contains("pub enum Result"))
  assert_true(output.contains("Ok(String)"))
  assert_true(output.contains("Err(String)"))
}

///|
test "rust: emit enum with struct variant" {
  let event = @ir.Enum::new("Event").with_variant(
    @ir.Variant::new("UserCreated").with_struct([
      @ir.Field::new("userId", @ir.Type::int64()),
      @ir.Field::new("name", @ir.Type::string()),
    ]),
  )
  let output = RustEmitter::new().emit_enum(event)
  assert_true(output.contains("pub enum Event"))
  assert_true(output.contains("UserCreated {"))
  assert_true(output.contains("user_id: i64"))
  assert_true(output.contains("name: String"))
}

///|
test "rust: emit struct with generics" {
  let response = @ir.Struct::new("Response")
    .with_type_params(["T"])
    .with_field(@ir.Field::new("data", @ir.Type::named("T")))
    .with_field(@ir.Field::new("success", @ir.Type::bool()))
  let output = RustEmitter::new().emit_struct(response)
  assert_true(output.contains("pub struct Response<T>"))
  assert_true(output.contains("pub data: T"))
  assert_true(output.contains("pub success: bool"))
}

///|
test "rust: without serde" {
  let user = @ir.Struct::new("User").with_field(
    @ir.Field::new("id", @ir.Type::int()),
  )
  let output = RustEmitter::new().without_serde().emit_struct(user)
  assert_true(output.contains("#[derive(Debug, Clone)]"))
  assert_true(not(output.contains("Serialize")))
  assert_true(not(output.contains("Deserialize")))
  assert_true(not(output.contains("serde")))
}

///|
test "rust: private fields" {
  let user = @ir.Struct::new("User").with_field(
    @ir.Field::new("id", @ir.Type::int()),
  )
  let output = RustEmitter::new().with_private_fields().emit_struct(user)
  assert_true(output.contains("id: i32"))
  assert_true(not(output.contains("pub id")))
}

///|
test "rust: primitive type mapping" {
  let types_struct = @ir.Struct::new("AllTypes")
    .with_field(@ir.Field::new("b", @ir.Type::bool()))
    .with_field(@ir.Field::new("i32", @ir.Type::int()))
    .with_field(@ir.Field::new("i64", @ir.Type::int64()))
    .with_field(@ir.Field::new("u32", @ir.Type::uint()))
    .with_field(@ir.Field::new("u64", @ir.Type::uint64()))
    .with_field(@ir.Field::new("f64", @ir.Type::double()))
    .with_field(@ir.Field::new("s", @ir.Type::string()))
    .with_field(@ir.Field::new("data", @ir.Type::bytes()))
  let output = RustEmitter::new().emit_struct(types_struct)
  assert_true(output.contains("pub b: bool"))
  assert_true(output.contains("pub i32: i32"))
  assert_true(output.contains("pub i64: i64"))
  assert_true(output.contains("pub u32: u32"))
  assert_true(output.contains("pub u64: u64"))
  assert_true(output.contains("pub f64: f64"))
  assert_true(output.contains("pub s: String"))
  assert_true(output.contains("pub data: Vec<u8>"))
}

///|
test "rust: map type with hashmap import" {
  let config = @ir.Struct::new("Config").with_field(
    @ir.Field::new(
      "settings",
      @ir.Type::map(@ir.Type::string(), @ir.Type::int()),
    ),
  )
  let mod = @ir.Module::new().add_struct(config)
  let output = RustEmitter::new().emit_module(mod)
  assert_true(output.contains("use std::collections::HashMap"))
  assert_true(output.contains("pub settings: HashMap<String, i32>"))
}

///|
test "rust: tuple type" {
  let point = @ir.Struct::new("Point").with_field(
    @ir.Field::new(
      "coords",
      @ir.Type::tuple([@ir.Type::int(), @ir.Type::int()]),
    ),
  )
  let output = RustEmitter::new().emit_struct(point)
  assert_true(output.contains("pub coords: (i32, i32)"))
}

///|
test "rust: function type" {
  let handler = @ir.Struct::new("Handler").with_field(
    @ir.Field::new(
      "callback",
      @ir.Type::function([@ir.Type::string()], @ir.Type::bool()),
    ),
  )
  let output = RustEmitter::new().emit_struct(handler)
  assert_true(output.contains("pub callback: fn(String) -> bool"))
}

///|
test "rust: type alias" {
  let type_alias = @ir.TypeAlias::new("UserId", @ir.Type::int64()).with_doc(
    "User identifier type",
  )
  let mod = @ir.Module::new().add_type_alias(type_alias)
  let output = RustEmitter::new().emit_module(mod)
  assert_true(output.contains("/// User identifier type"))
  assert_true(output.contains("pub type UserId = i64"))
}

///|
test "rust: const declaration" {
  let const_decl = @ir.ConstDecl::new("MAX_SIZE", "1000")
    .with_type(@ir.Type::int())
    .with_doc("Maximum allowed size")
  let mod = @ir.Module::new().add_const(const_decl)
  let output = RustEmitter::new().emit_module(mod)
  assert_true(output.contains("/// Maximum allowed size"))
  assert_true(output.contains("pub const MAX_SIZE: i32 = 1000"))
}

///|
test "rust: snake_case field names" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("firstName", @ir.Type::string()))
    .with_field(@ir.Field::new("lastName", @ir.Type::string()))
  let output = RustEmitter::new().emit_struct(user)
  assert_true(output.contains("pub first_name: String"))
  assert_true(output.contains("pub last_name: String"))
}

///|
test "rust: module with serde import" {
  let user = @ir.Struct::new("User").with_field(
    @ir.Field::new("id", @ir.Type::int()),
  )
  let mod = @ir.Module::new().add_struct(user)
  let output = RustEmitter::new().emit_module(mod)
  assert_true(output.contains("// Generated code - do not edit"))
  assert_true(output.contains("use serde::{Deserialize, Serialize}"))
}
