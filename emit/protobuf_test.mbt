///|
/// Protocol Buffers emitter tests

///|
test "protobuf: emit basic message" {
  let user = @ir.Struct::new("User")
    .with_doc("A user in the system")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()))
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))
  let output = ProtoEmitter::new().emit_struct(user)
  assert_true(output.contains("// A user in the system"))
  assert_true(output.contains("message User"))
  assert_true(output.contains("int64 id = 1"))
  assert_true(output.contains("string name = 2"))
  assert_true(output.contains("optional string email = 3"))
  assert_true(output.contains("repeated string tags = 4"))
}

///|
test "protobuf: emit simple enum" {
  let status = @ir.Enum::new("Status")
    .with_doc("User account status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
    .with_variant(@ir.Variant::new("Pending"))
  let output = ProtoEmitter::new().emit_enum(status)
  assert_true(output.contains("// User account status"))
  assert_true(output.contains("enum Status"))
  // Proto3 requires SCREAMING_SNAKE_CASE and starts from 0
  assert_true(output.contains("ACTIVE = 0"))
  assert_true(output.contains("INACTIVE = 1"))
  assert_true(output.contains("PENDING = 2"))
}

///|
test "protobuf: emit complex enum as oneof" {
  let result = @ir.Enum::new("Result")
    .with_variant(@ir.Variant::new("Ok").with_tuple([@ir.Type::string()]))
    .with_variant(@ir.Variant::new("Err").with_tuple([@ir.Type::string()]))
  let output = ProtoEmitter::new().emit_enum(result)
  // Complex enums use oneof
  assert_true(output.contains("message Result"))
  assert_true(output.contains("oneof variant"))
  assert_true(output.contains("ResultOk ok = 1"))
  assert_true(output.contains("ResultErr err = 2"))
  // Nested message types
  assert_true(output.contains("message ResultOk"))
  assert_true(output.contains("message ResultErr"))
}

///|
test "protobuf: emit module with syntax and package" {
  let mod = @ir.Module::new()
    .with_name("myapp/users")
    .add_struct(
      @ir.Struct::new("User")
      .with_field(@ir.Field::new("id", @ir.Type::int64()))
      .with_field(@ir.Field::new("name", @ir.Type::string())),
    )
    .add_enum(
      @ir.Enum::new("Status")
      .with_variant(@ir.Variant::new("Active"))
      .with_variant(@ir.Variant::new("Inactive")),
    )
  let output = ProtoEmitter::new().emit_module(mod)
  assert_true(output.contains("syntax = \"proto3\""))
  assert_true(output.contains("package myapp.users"))
  assert_true(output.contains("message User"))
  assert_true(output.contains("enum Status"))
}

///|
test "protobuf: primitive type mapping" {
  let types_struct = @ir.Struct::new("AllTypes")
    .with_field(@ir.Field::new("b", @ir.Type::bool()))
    .with_field(@ir.Field::new("i32", @ir.Type::int()))
    .with_field(@ir.Field::new("i64", @ir.Type::int64()))
    .with_field(@ir.Field::new("u32", @ir.Type::uint()))
    .with_field(@ir.Field::new("u64", @ir.Type::uint64()))
    .with_field(@ir.Field::new("f64", @ir.Type::double()))
    .with_field(@ir.Field::new("s", @ir.Type::string()))
    .with_field(@ir.Field::new("data", @ir.Type::bytes()))
  let output = ProtoEmitter::new().emit_struct(types_struct)
  assert_true(output.contains("bool b = 1"))
  assert_true(output.contains("int32 i32 = 2"))
  assert_true(output.contains("int64 i64 = 3"))
  assert_true(output.contains("uint32 u32 = 4"))
  assert_true(output.contains("uint64 u64 = 5"))
  assert_true(output.contains("double f64 = 6"))
  assert_true(output.contains("string s = 7"))
  assert_true(output.contains("bytes data = 8"))
}

///|
test "protobuf: map type" {
  let config = @ir.Struct::new("Config").with_field(
    @ir.Field::new(
      "settings",
      @ir.Type::map(@ir.Type::string(), @ir.Type::int()),
    ),
  )
  let output = ProtoEmitter::new().emit_struct(config)
  assert_true(output.contains("map<string, int32> settings = 1"))
}

///|
test "protobuf: nested type" {
  let user = @ir.Struct::new("User").with_field(
    @ir.Field::new("profile", @ir.Type::named("Profile")),
  )
  let output = ProtoEmitter::new().emit_struct(user)
  assert_true(output.contains("Profile profile = 1"))
}

///|
test "protobuf: enum variant with struct payload" {
  let event = @ir.Enum::new("Event")
    .with_variant(
      @ir.Variant::new("UserCreated").with_struct([
        @ir.Field::new("userId", @ir.Type::int64()),
        @ir.Field::new("name", @ir.Type::string()),
      ]),
    )
    .with_variant(
      @ir.Variant::new("UserDeleted").with_tuple([@ir.Type::int64()]),
    )
  let output = ProtoEmitter::new().emit_enum(event)
  assert_true(output.contains("message EventUserCreated"))
  assert_true(output.contains("int64 user_id = 1"))
  assert_true(output.contains("string name = 2"))
  assert_true(output.contains("message EventUserDeleted"))
  assert_true(output.contains("int64 value0 = 1"))
}
