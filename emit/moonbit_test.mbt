///|
test "emit simple struct" {
  let s = @ir.Struct::new("User")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()))
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
  let emitter = MoonBitEmitter::new()
  let code = emitter.emit_struct(s)
  let expected =
    #|///|
    #|pub struct User {
    #|  id : Int64
    #|  name : String
    #|  email : String?
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit struct with doc and derive" {
  let s = @ir.Struct::new("Point")
    .with_doc("A 2D point")
    .with_derives(["Show", "Eq"])
    .with_field(@ir.Field::new("x", @ir.Type::double()))
    .with_field(@ir.Field::new("y", @ir.Type::double()))
  let emitter = MoonBitEmitter::new()
  let code = emitter.emit_struct(s)
  let expected =
    #|///|
    #|/// A 2D point
    #|#derive(Show)
    #|#derive(Eq)
    #|pub struct Point {
    #|  x : Double
    #|  y : Double
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit enum" {
  let e = @ir.Enum::new("Result")
    .with_type_params(["T", "E"])
    .with_variant(@ir.Variant::new("Ok").with_tuple([@ir.Type::named("T")]))
    .with_variant(@ir.Variant::new("Err").with_tuple([@ir.Type::named("E")]))
  let emitter = MoonBitEmitter::new()
  let code = emitter.emit_enum(e)
  let expected =
    #|///|
    #|pub enum Result[T, E] {
    #|  Ok(T)
    #|  Err(E)
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit function" {
  let f = @ir.Function::new("add")
    .with_param(@ir.Param::new("a", @ir.Type::int()))
    .with_param(@ir.Param::new("b", @ir.Type::int()))
    .with_return(@ir.Type::int())
    .with_body("a + b")
  let emitter = MoonBitEmitter::new()
  let code = emitter.emit_function(f)
  let expected =
    #|///|
    #|pub fn add(a : Int, b : Int) -> Int {
    #|  a + b
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit async function with error" {
  let f = @ir.Function::new("fetch_data")
    .with_param(@ir.Param::new("url", @ir.Type::string()))
    .with_return(@ir.Type::bytes())
    .with_error(@ir.Type::named("FetchError"))
    .as_async()
    .with_body("// async fetch implementation")
  let emitter = MoonBitEmitter::new()
  let code = emitter.emit_function(f)
  let expected =
    #|///|
    #|pub async fn fetch_data(url : String) -> Bytes raise FetchError {
    #|  // async fetch implementation
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit module" {
  let mod = @ir.Module::new()
    .add_struct(
      @ir.Struct::new("User")
      .with_field(@ir.Field::new("id", @ir.Type::int64()))
      .with_field(@ir.Field::new("name", @ir.Type::string())),
    )
    .add_function(
      @ir.Function::new("create_user")
      .with_param(@ir.Param::new("name", @ir.Type::string()))
      .with_return(@ir.Type::named("User"))
      .with_body("{ id: 1L, name }"),
    )
  let emitter = MoonBitEmitter::new()
  let code = emitter.emit_module(mod)
  let expected =
    #|///|
    #|pub struct User {
    #|  id : Int64
    #|  name : String
    #|}
    #|
    #|///|
    #|pub fn create_user(name : String) -> User {
    #|  { id: 1L, name }
    #|}
    #|
  inspect(code, content=expected)
}
