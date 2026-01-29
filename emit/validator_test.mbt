///|
test "emit struct validator with required string" {
  let s = @ir.Struct::new("CreateUserParams")
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
        .as_required(),
    )
  let emitter = ValidatorEmitter::new()
  let code = emitter.emit_struct_validator(s)
  let expected =
    #|///|
    #|/// Validate CreateUserParams
    #|pub fn CreateUserParams::validate(self : CreateUserParams) -> Result[Unit, String] {
    #|  if self.name.length() == 0 {
    #|    return Err("name is required")
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit struct validator with max length" {
  let s = @ir.Struct::new("UpdateUserParams")
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
        .with_max_length(100),
    )
  let emitter = ValidatorEmitter::new()
  let code = emitter.emit_struct_validator(s)
  let expected =
    #|///|
    #|/// Validate UpdateUserParams
    #|pub fn UpdateUserParams::validate(self : UpdateUserParams) -> Result[Unit, String] {
    #|  if self.name.length() > 100 {
    #|    return Err("name must be at most 100 characters")
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit struct validator with unsigned int" {
  let s = @ir.Struct::new("ProductParams")
    .with_field(
      @ir.Field::new("quantity", @ir.Type::int64())
        .as_unsigned(),
    )
  let emitter = ValidatorEmitter::new()
  let code = emitter.emit_struct_validator(s)
  let expected =
    #|///|
    #|/// Validate ProductParams
    #|pub fn ProductParams::validate(self : ProductParams) -> Result[Unit, String] {
    #|  if self.quantity < 0L {
    #|    return Err("quantity must be non-negative")
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit struct validator with optional field" {
  let s = @ir.Struct::new("SearchParams")
    .with_field(
      @ir.Field::new("query", @ir.Type::optional(@ir.Type::string()))
        .with_max_length(200),
    )
  let emitter = ValidatorEmitter::new()
  let code = emitter.emit_struct_validator(s)
  let expected =
    #|///|
    #|/// Validate SearchParams
    #|pub fn SearchParams::validate(self : SearchParams) -> Result[Unit, String] {
    #|  match self.query {
    #|    Some(v) => if v.length() > 200 {
    #|      return Err("query must be at most 200 characters")
    #|    }
    #|    None => ()
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "emit struct validator with no constraints" {
  let s = @ir.Struct::new("EmptyParams")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
  let emitter = ValidatorEmitter::new()
  let code = emitter.emit_struct_validator(s)
  let expected =
    #|///|
    #|/// Validate EmptyParams
    #|pub fn EmptyParams::validate(_self : EmptyParams) -> Result[Unit, String] {
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}
