///|
/// TypeScript emitter tests

///|
test "typescript: emit basic struct" {
  let user = @ir.Struct::new("User")
    .with_doc("A user in the system")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()))
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))
  let output = TsEmitter::new().emit_struct(user)
  assert_true(output.contains("export interface User"))
  assert_true(output.contains("readonly id: number"))
  assert_true(output.contains("readonly name: string"))
  assert_true(output.contains("email?: string | null"))
  assert_true(output.contains("readonly tags: string[]"))
  assert_true(output.contains("/**"))
  assert_true(output.contains("A user in the system"))
}

///|
test "typescript: emit simple enum" {
  let status = @ir.Enum::new("Status")
    .with_doc("User account status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
    .with_variant(@ir.Variant::new("Pending"))
  let output = TsEmitter::new().emit_enum(status)
  assert_true(output.contains("export enum Status"))
  assert_true(output.contains("Active,"))
  assert_true(output.contains("Inactive,"))
  assert_true(output.contains("Pending,"))
}

///|
test "typescript: emit complex enum as discriminated union" {
  let result = @ir.Enum::new("Result")
    .with_variant(@ir.Variant::new("Ok").with_tuple([@ir.Type::string()]))
    .with_variant(@ir.Variant::new("Err").with_tuple([@ir.Type::string()]))
  let output = TsEmitter::new().emit_enum(result)
  // Should create discriminated union with type field
  assert_true(output.contains("export interface ResultOk"))
  assert_true(output.contains("export interface ResultErr"))
  assert_true(output.contains("readonly type: \"Ok\""))
  assert_true(output.contains("readonly type: \"Err\""))
  assert_true(output.contains("export type Result ="))
  assert_true(output.contains("| ResultOk"))
  assert_true(output.contains("| ResultErr"))
}

///|
test "typescript: emit struct with generics" {
  let result = @ir.Struct::new("Response")
    .with_type_params(["T"])
    .with_field(@ir.Field::new("data", @ir.Type::named("T")))
    .with_field(@ir.Field::new("success", @ir.Type::bool()))
  let output = TsEmitter::new().emit_struct(result)
  assert_true(output.contains("export interface Response<T>"))
  assert_true(output.contains("readonly data: T"))
  assert_true(output.contains("readonly success: boolean"))
}

///|
test "typescript: emit mutable field without readonly" {
  let user = @ir.Struct::new("User").with_field(
    @ir.Field::new("name", @ir.Type::string()).as_mutable(),
  )
  let output = TsEmitter::new().emit_struct(user)
  assert_true(output.contains("name: string"))
  assert_true(not(output.contains("readonly name")))
}

///|
test "typescript: without exports" {
  let user = @ir.Struct::new("User").with_field(
    @ir.Field::new("id", @ir.Type::int()),
  )
  let output = TsEmitter::new().without_exports().emit_struct(user)
  assert_true(output.contains("interface User"))
  assert_true(not(output.contains("export interface")))
}

///|
test "typescript: map types" {
  let config = @ir.Struct::new("Config").with_field(
    @ir.Field::new(
      "settings",
      @ir.Type::map(@ir.Type::string(), @ir.Type::int()),
    ),
  )
  let output = TsEmitter::new().emit_struct(config)
  assert_true(output.contains("readonly settings: Record<string, number>"))
}

///|
test "typescript: function type" {
  let handler = @ir.Struct::new("Handler").with_field(
    @ir.Field::new(
      "callback",
      @ir.Type::function([@ir.Type::string()], @ir.Type::bool()),
    ),
  )
  let output = TsEmitter::new().emit_struct(handler)
  assert_true(output.contains("readonly callback: (arg0: string) => boolean"))
}

///|
test "typescript: tuple type" {
  let point = @ir.Struct::new("Point").with_field(
    @ir.Field::new(
      "coords",
      @ir.Type::tuple([@ir.Type::int(), @ir.Type::int()]),
    ),
  )
  let output = TsEmitter::new().emit_struct(point)
  assert_true(output.contains("readonly coords: [number, number]"))
}

///|
test "typescript: type alias" {
  let type_alias = @ir.TypeAlias::new("UserId", @ir.Type::int64()).with_doc(
    "User identifier type",
  )
  let mod = @ir.Module::new().add_type_alias(type_alias)
  let output = TsEmitter::new().emit_module(mod)
  assert_true(output.contains("export type UserId = number"))
}

///|
test "typescript: const declaration" {
  let const_decl = @ir.ConstDecl::new("MAX_SIZE", "1000")
    .with_type(@ir.Type::int())
    .with_doc("Maximum allowed size")
  let mod = @ir.Module::new().add_const(const_decl)
  let output = TsEmitter::new().emit_module(mod)
  assert_true(output.contains("export const MAX_SIZE: number = 1000"))
}
