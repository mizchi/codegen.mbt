///|
/// Integration tests: verify all emitters work together from the same IR

///|
test "all emitters produce output from same struct" {
  // Define a struct with various features
  let user = @ir.Struct::new("User")
    .with_doc("A user in the system")
    .with_derives(["Show", "Eq"])
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
      .as_required()
      .with_max_length(100),
    )
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
    .with_field(@ir.Field::new("age", @ir.Type::int64()).as_unsigned())
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))

  // MoonBit output
  let moonbit = MoonBitEmitter::new().emit_struct(user)
  assert_true(moonbit.contains("pub struct User"))
  assert_true(moonbit.contains("id : Int64"))
  assert_true(moonbit.contains("name : String"))
  assert_true(moonbit.contains("email : String?"))
  assert_true(moonbit.contains("tags : Array[String]"))
  assert_true(moonbit.contains("#derive(Show)"))

  // JSON Schema output
  let jsonschema = JsonSchemaEmitter::new().emit_struct(user)
  assert_true(jsonschema.contains("\"type\": \"object\""))
  assert_true(jsonschema.contains("\"title\": \"User\""))
  assert_true(jsonschema.contains("\"properties\""))
  assert_true(jsonschema.contains("\"maxLength\": 100"))
  assert_true(jsonschema.contains("\"minimum\": 0")) // unsigned

  // Validator output
  let validator = ValidatorEmitter::new().emit_struct_validator(user)
  assert_true(validator.contains("pub fn User::validate"))
  assert_true(validator.contains("name is required"))
  assert_true(validator.contains("name must be at most 100 characters"))
  assert_true(validator.contains("age must be non-negative"))

  // FlatBuffers output
  let fbs = FbsEmitter::new().emit_struct(user)
  assert_true(fbs.contains("table User"))
  assert_true(fbs.contains("id:long"))
  assert_true(fbs.contains("name:string"))
  assert_true(fbs.contains("tags:[string]"))
}

///|
test "all emitters produce output from same enum" {
  let status = @ir.Enum::new("Status")
    .with_doc("User account status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
    .with_variant(@ir.Variant::new("Pending"))

  // MoonBit output
  let moonbit = MoonBitEmitter::new().emit_enum(status)
  assert_true(moonbit.contains("pub enum Status"))
  assert_true(moonbit.contains("Active"))
  assert_true(moonbit.contains("Inactive"))
  assert_true(moonbit.contains("Pending"))

  // JSON Schema output
  let jsonschema = JsonSchemaEmitter::new().emit_enum(status)
  assert_true(jsonschema.contains("\"title\": \"Status\""))
  assert_true(jsonschema.contains("\"enum\""))
  assert_true(jsonschema.contains("\"Active\""))

  // FlatBuffers output
  let fbs = FbsEmitter::new().emit_enum(status)
  assert_true(fbs.contains("enum Status"))
  assert_true(fbs.contains("Active"))
}

///|
test "module with multiple items" {
  let mod = @ir.Module::new()
    .with_name("myapp")
    .add_struct(
      @ir.Struct::new("User")
      .with_field(@ir.Field::new("id", @ir.Type::int64()))
      .with_field(@ir.Field::new("name", @ir.Type::string())),
    )
    .add_struct(
      @ir.Struct::new("Post")
      .with_field(@ir.Field::new("id", @ir.Type::int64()))
      .with_field(@ir.Field::new("title", @ir.Type::string()))
      .with_field(@ir.Field::new("authorId", @ir.Type::int64())),
    )
    .add_enum(
      @ir.Enum::new("PostStatus")
      .with_variant(@ir.Variant::new("Draft"))
      .with_variant(@ir.Variant::new("Published")),
    )

  // MoonBit module
  let moonbit = MoonBitEmitter::new().emit_module(mod)
  assert_true(moonbit.contains("pub struct User"))
  assert_true(moonbit.contains("pub struct Post"))
  assert_true(moonbit.contains("pub enum PostStatus"))

  // FlatBuffers schema
  let fbs = FbsEmitter::new().emit_module(mod)
  assert_true(fbs.contains("namespace myapp"))
  assert_true(fbs.contains("table User"))
  assert_true(fbs.contains("table Post"))
  assert_true(fbs.contains("enum PostStatus"))
}

///|
test "roundtrip: builder to emitter" {
  // Use builder pattern
  let user = @builder.StructBuilder::new("Person")
    .with_doc("A person")
    .add_field("first_name", @ir.Type::string())
    .add_field("last_name", @ir.Type::string())
    .add_field("age", @ir.Type::int())
    .build()

  // Emit to all formats
  let moonbit = MoonBitEmitter::new().emit_struct(user)
  let jsonschema = JsonSchemaEmitter::new().emit_struct(user)
  let fbs = FbsEmitter::new().emit_struct(user)

  // Verify outputs
  assert_true(moonbit.contains("pub struct Person"))
  assert_true(moonbit.contains("first_name : String"))
  assert_true(jsonschema.contains("\"title\": \"Person\""))
  assert_true(fbs.contains("table Person"))
}

///|
test "function emitter" {
  let func = @ir.Function::new("createUser")
    .with_doc("Create a new user")
    .with_param(@ir.Param::new("name", @ir.Type::string()))
    .with_param(@ir.Param::new("email", @ir.Type::string()))
    .with_return(@ir.Type::named("User"))
    .with_body("{ id: 1L, name, email, age: 0L, tags: [] }")
  let moonbit = MoonBitEmitter::new().emit_function(func)
  assert_true(moonbit.contains("pub fn createUser"))
  assert_true(moonbit.contains("name : String"))
  assert_true(moonbit.contains("-> User"))
}
