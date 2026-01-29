///|
test "emit struct as fbs table" {
  let s = @ir.Struct::new("User")
    .with_doc("A user record")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()))
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))
  let emitter = FbsEmitter::new()
  let code = emitter.emit_struct(s)
  let expected =
    #|/// A user record
    #|table User {
    #|  id:long;
    #|  name:string;
    #|  email:string;
    #|  tags:[string];
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit struct as fbs struct" {
  let s = @ir.Struct::new("Point")
    .with_field(@ir.Field::new("x", @ir.Type::double()))
    .with_field(@ir.Field::new("y", @ir.Type::double()))
  let emitter = FbsEmitter::new().with_structs()
  let code = emitter.emit_struct(s)
  let expected =
    #|struct Point {
    #|  x:double;
    #|  y:double;
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit simple enum as fbs" {
  let e = @ir.Enum::new("Status")
    .with_doc("User status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
    .with_variant(@ir.Variant::new("Pending"))
  let emitter = FbsEmitter::new()
  let code = emitter.emit_enum(e)
  let expected =
    #|/// User status
    #|enum Status : ubyte {
    #|  Active,
    #|  Inactive,
    #|  Pending
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit module as fbs schema" {
  let mod = @ir.Module::new()
    .with_name("myapp")
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
  let emitter = FbsEmitter::new()
  let code = emitter.emit_module(mod)
  let expected =
    #|namespace myapp;
    #|
    #|table User {
    #|  id:long;
    #|  name:string;
    #|}
    #|
    #|enum Status : ubyte {
    #|  Active,
    #|  Inactive
    #|}
    #|
  inspect(code, content=expected)
}
