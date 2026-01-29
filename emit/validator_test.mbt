///|
test "emit struct validator with required string" {
  let s = @ir.Struct::new("CreateUserParams").with_field(
    @ir.Field::new("name", @ir.Type::string()).as_required(),
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
  let s = @ir.Struct::new("UpdateUserParams").with_field(
    @ir.Field::new("name", @ir.Type::string()).with_max_length(100),
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
  let s = @ir.Struct::new("ProductParams").with_field(
    @ir.Field::new("quantity", @ir.Type::int64()).as_unsigned(),
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
  let s = @ir.Struct::new("SearchParams").with_field(
    @ir.Field::new("query", @ir.Type::optional(@ir.Type::string())).with_max_length(
      200,
    ),
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
  let s = @ir.Struct::new("EmptyParams").with_field(
    @ir.Field::new("id", @ir.Type::int64()),
  )
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

///|
test "snapshot: comprehensive validator with multiple constraints" {
  let user = @ir.Struct::new("User")
    .with_field(
      @ir.Field::new("id", @ir.Type::int64())
      .as_unsigned()
      .with_min_value(1L),
    )
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
      .as_required()
      .with_min_length(1)
      .with_max_length(100),
    )
    .with_field(
      @ir.Field::new("email", @ir.Type::optional(@ir.Type::string()))
      .with_max_length(255),
    )
    .with_field(
      @ir.Field::new("age", @ir.Type::int64())
      .as_unsigned()
      .with_min_value(0L)
      .with_max_value(150L),
    )
  let code = ValidatorEmitter::new().emit_struct_validator(user)
  let expected =
    #|///|
    #|/// Validate User
    #|pub fn User::validate(self : User) -> Result[Unit, String] {
    #|  if self.id < 0L {
    #|    return Err("id must be non-negative")
    #|  }
    #|  if self.id < 1L {
    #|    return Err("id must be at least 1")
    #|  }
    #|  if self.name.length() == 0 {
    #|    return Err("name is required")
    #|  }
    #|  if self.name.length() < 1 {
    #|    return Err("name must be at least 1 characters")
    #|  }
    #|  if self.name.length() > 100 {
    #|    return Err("name must be at most 100 characters")
    #|  }
    #|  match self.email {
    #|    Some(v) => if v.length() > 255 {
    #|      return Err("email must be at most 255 characters")
    #|    }
    #|    None => ()
    #|  }
    #|  if self.age < 0L {
    #|    return Err("age must be non-negative")
    #|  }
    #|  if self.age < 0L {
    #|    return Err("age must be at least 0")
    #|  }
    #|  if self.age > 150L {
    #|    return Err("age must be at most 150")
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: validator with min_length only" {
  let params = @ir.Struct::new("SearchParams")
    .with_field(
      @ir.Field::new("query", @ir.Type::string())
      .with_min_length(3),
    )
  let code = ValidatorEmitter::new().emit_struct_validator(params)
  let expected =
    #|///|
    #|/// Validate SearchParams
    #|pub fn SearchParams::validate(self : SearchParams) -> Result[Unit, String] {
    #|  if self.query.length() < 3 {
    #|    return Err("query must be at least 3 characters")
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: validator with numeric range" {
  let config = @ir.Struct::new("Config")
    .with_field(
      @ir.Field::new("port", @ir.Type::int64())
      .with_min_value(1L)
      .with_max_value(65535L),
    )
    .with_field(
      @ir.Field::new("timeout", @ir.Type::int64())
      .as_unsigned(),
    )
  let code = ValidatorEmitter::new().emit_struct_validator(config)
  let expected =
    #|///|
    #|/// Validate Config
    #|pub fn Config::validate(self : Config) -> Result[Unit, String] {
    #|  if self.port < 1L {
    #|    return Err("port must be at least 1")
    #|  }
    #|  if self.port > 65535L {
    #|    return Err("port must be at most 65535")
    #|  }
    #|  if self.timeout < 0L {
    #|    return Err("timeout must be non-negative")
    #|  }
    #|  Ok(())
    #|}
    #|
  inspect(code, content=expected)
}
