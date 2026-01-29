///|
/// Zod emitter tests

///|
test "zod: emit struct parser" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()).as_required())
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))

  let output = ZodEmitter::new().emit_struct_parser(user)
  assert_true(output.contains("pub fn User::from_json(json : Json) -> Result[User, String]"))
  assert_true(output.contains("guard let Json::Object(obj) = json"))
  assert_true(output.contains("obj[\"id\"]"))
  assert_true(output.contains("obj[\"name\"]"))
  assert_true(output.contains("obj[\"email\"]"))
  assert_true(output.contains("Ok({ id, name, email })"))
}

///|
test "zod: emit struct serializer" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()))

  let output = ZodEmitter::new().emit_struct_serializer(user)
  assert_true(output.contains("pub fn User::to_json(self : User) -> Json"))
  assert_true(output.contains("let obj : Map[String, Json] = {}"))
  assert_true(output.contains("obj[\"id\"]"))
  assert_true(output.contains("obj[\"name\"]"))
  assert_true(output.contains("Json::Object(obj)"))
}

///|
test "zod: emit struct with validation" {
  let user = @ir.Struct::new("User")
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
      .as_required()
      .with_min_length(1)
      .with_max_length(100),
    )
    .with_field(@ir.Field::new("age", @ir.Type::int64()).as_unsigned())

  let output = ZodEmitter::new().emit_struct_parser(user)
  assert_true(output.contains("name cannot be empty"))
  assert_true(output.contains("name must be at least 1 characters"))
  assert_true(output.contains("name must be at most 100 characters"))
  assert_true(output.contains("age must be non-negative"))
}

///|
test "zod: emit simple enum parser" {
  let status = @ir.Enum::new("Status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))

  let output = ZodEmitter::new().emit_enum_parser(status)
  assert_true(output.contains("pub fn Status::from_json(json : Json) -> Result[Status, String]"))
  assert_true(output.contains("guard let Json::String(s) = json"))
  assert_true(output.contains("\"Active\" => Ok(Status::Active)"))
  assert_true(output.contains("\"Inactive\" => Ok(Status::Inactive)"))
}

///|
test "zod: emit simple enum serializer" {
  let status = @ir.Enum::new("Status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))

  let output = ZodEmitter::new().emit_enum_serializer(status)
  assert_true(output.contains("pub fn Status::to_json(self : Status) -> Json"))
  assert_true(output.contains("Status::Active => Json::String(\"Active\")"))
  assert_true(output.contains("Status::Inactive => Json::String(\"Inactive\")"))
}

///|
test "zod: emit tagged union enum" {
  let result = @ir.Enum::new("Result")
    .with_variant(@ir.Variant::new("Ok").with_tuple([@ir.Type::string()]))
    .with_variant(@ir.Variant::new("Err").with_tuple([@ir.Type::string()]))

  let output = ZodEmitter::new().emit_enum_parser(result)
  assert_true(output.contains("guard let Json::Object(obj) = json"))
  assert_true(output.contains("obj[\"type\"]"))
  assert_true(output.contains("\"Ok\" =>"))
  assert_true(output.contains("\"Err\" =>"))
}

///|
test "zod: emit helpers" {
  let output = ZodEmitter::new().emit_helpers()
  assert_true(output.contains("fn parse_string(json : Json) -> Result[String, String]"))
  assert_true(output.contains("fn parse_int(json : Json) -> Result[Int, String]"))
  assert_true(output.contains("fn parse_int64(json : Json) -> Result[Int64, String]"))
  assert_true(output.contains("fn parse_double(json : Json) -> Result[Double, String]"))
  assert_true(output.contains("fn parse_bool(json : Json) -> Result[Bool, String]"))
  assert_true(output.contains("fn parse_array"))
  assert_true(output.contains("fn parse_map"))
}

///|
test "zod: emit module" {
  let mod = @ir.Module::new()
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

  let output = ZodEmitter::new().emit_module(mod)
  // Should have helpers
  assert_true(output.contains("fn parse_string"))
  // Should have User parser and serializer
  assert_true(output.contains("pub fn User::from_json"))
  assert_true(output.contains("pub fn User::to_json"))
  // Should have Status parser and serializer
  assert_true(output.contains("pub fn Status::from_json"))
  assert_true(output.contains("pub fn Status::to_json"))
}

///|
test "zod: array field" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))

  let output = ZodEmitter::new().emit_struct_parser(user)
  assert_true(output.contains("parse_array"))
}

///|
test "zod: nested struct field" {
  let post = @ir.Struct::new("Post")
    .with_field(@ir.Field::new("author", @ir.Type::named("User")))

  let output = ZodEmitter::new().emit_struct_parser(post)
  assert_true(output.contains("User::from_json"))
}

///|
test "snapshot: simple struct parser" {
  let point = @ir.Struct::new("Point")
    .with_field(@ir.Field::new("x", @ir.Type::double()))
    .with_field(@ir.Field::new("y", @ir.Type::double()))
  let code = ZodEmitter::new().emit_struct_parser(point)
  let expected =
    #|///|
    #|/// Parse Point from JSON with validation
    #|pub fn Point::from_json(json : Json) -> Result[Point, String] {
    #|  guard let Json::Object(obj) = json else {
    #|    return Err("Expected object for Point")
    #|  }
    #|  let x : Double = match obj["x"] {
    #|    Some(v) => {
    #|      match parse_double(v) {
    #|        Ok(parsed) => {
    #|          parsed
    #|        }
    #|        Err(e) => return Err("x: " + e)
    #|      }
    #|    }
    #|    None => return Err("Missing field: x")
    #|  }
    #|  let y : Double = match obj["y"] {
    #|    Some(v) => {
    #|      match parse_double(v) {
    #|        Ok(parsed) => {
    #|          parsed
    #|        }
    #|        Err(e) => return Err("y: " + e)
    #|      }
    #|    }
    #|    None => return Err("Missing field: y")
    #|  }
    #|  Ok({ x, y })
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: simple struct serializer" {
  let point = @ir.Struct::new("Point")
    .with_field(@ir.Field::new("x", @ir.Type::double()))
    .with_field(@ir.Field::new("y", @ir.Type::double()))
  let code = ZodEmitter::new().emit_struct_serializer(point)
  let expected =
    #|///|
    #|/// Serialize Point to JSON
    #|pub fn Point::to_json(self : Point) -> Json {
    #|  let obj : Map[String, Json] = {}
    #|  obj["x"] = Json::Number(self.x.to_double())
    #|  obj["y"] = Json::Number(self.y.to_double())
    #|  Json::Object(obj)
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: struct parser with validation" {
  let user = @ir.Struct::new("CreateUserInput")
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
      .as_required()
      .with_min_length(1)
      .with_max_length(50),
    )
    .with_field(
      @ir.Field::new("age", @ir.Type::int64())
      .as_unsigned(),
    )
  let code = ZodEmitter::new().emit_struct_parser(user)
  let expected =
    #|///|
    #|/// Parse CreateUserInput from JSON with validation
    #|pub fn CreateUserInput::from_json(json : Json) -> Result[CreateUserInput, String] {
    #|  guard let Json::Object(obj) = json else {
    #|    return Err("Expected object for CreateUserInput")
    #|  }
    #|  let name : String = match obj["name"] {
    #|    Some(v) => {
    #|      match parse_string(v) {
    #|        Ok(parsed) => {
    #|          if parsed.length() == 0 {
    #|            return Err("name cannot be empty")
    #|          }
    #|          if parsed.length() < 1 {
    #|            return Err("name must be at least 1 characters")
    #|          }
    #|          if parsed.length() > 50 {
    #|            return Err("name must be at most 50 characters")
    #|          }
    #|          parsed
    #|        }
    #|        Err(e) => return Err("name: " + e)
    #|      }
    #|    }
    #|    None => return Err("name is required")
    #|  }
    #|  let age : Int64 = match obj["age"] {
    #|    Some(v) => {
    #|      match parse_int64(v) {
    #|        Ok(parsed) => {
    #|          if parsed < 0L {
    #|            return Err("age must be non-negative")
    #|          }
    #|          parsed
    #|        }
    #|        Err(e) => return Err("age: " + e)
    #|      }
    #|    }
    #|    None => return Err("Missing field: age")
    #|  }
    #|  Ok({ name, age })
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: struct with optional field" {
  let user = @ir.Struct::new("UpdateUserInput")
    .with_field(@ir.Field::new("name", @ir.Type::optional(@ir.Type::string())))
  let code = ZodEmitter::new().emit_struct_parser(user)
  let expected =
    #|///|
    #|/// Parse UpdateUserInput from JSON with validation
    #|pub fn UpdateUserInput::from_json(json : Json) -> Result[UpdateUserInput, String] {
    #|  guard let Json::Object(obj) = json else {
    #|    return Err("Expected object for UpdateUserInput")
    #|  }
    #|  let name : String? = match obj["name"] {
    #|    Some(v) => {
    #|      guard let Json::Null != v else { None }
    #|      match parse_string(v) {
    #|        Ok(parsed) => {
    #|          Some(parsed)
    #|        }
    #|        Err(e) => return Err("name: " + e)
    #|      }
    #|    }
    #|    None => None
    #|  }
    #|  Ok({ name })
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: simple enum parser" {
  let status = @ir.Enum::new("Status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Pending"))
    .with_variant(@ir.Variant::new("Inactive"))
  let code = ZodEmitter::new().emit_enum_parser(status)
  let expected =
    #|///|
    #|/// Parse Status from JSON
    #|pub fn Status::from_json(json : Json) -> Result[Status, String] {
    #|  guard let Json::String(s) = json else {
    #|    return Err("Expected string for Status")
    #|  }
    #|  match s {
    #|    "Active" => Ok(Status::Active)
    #|    "Pending" => Ok(Status::Pending)
    #|    "Inactive" => Ok(Status::Inactive)
    #|    _ => Err("Unknown variant: " + s)
    #|  }
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: simple enum serializer" {
  let status = @ir.Enum::new("Status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
  let code = ZodEmitter::new().emit_enum_serializer(status)
  let expected =
    #|///|
    #|/// Serialize Status to JSON
    #|pub fn Status::to_json(self : Status) -> Json {
    #|  match self {
    #|    Status::Active => Json::String("Active")
    #|    Status::Inactive => Json::String("Inactive")
    #|  }
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: struct serializer with optional" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
  let code = ZodEmitter::new().emit_struct_serializer(user)
  let expected =
    #|///|
    #|/// Serialize User to JSON
    #|pub fn User::to_json(self : User) -> Json {
    #|  let obj : Map[String, Json] = {}
    #|  obj["id"] = Json::Number(self.id.to_double())
    #|  match self.email {
    #|    Some(v) => obj["email"] = Json::String(v)
    #|    None => obj["email"] = Json::Null
    #|  }
    #|  Json::Object(obj)
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: struct with array field" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))
  let code = ZodEmitter::new().emit_struct_parser(user)
  let expected =
    #|///|
    #|/// Parse User from JSON with validation
    #|pub fn User::from_json(json : Json) -> Result[User, String] {
    #|  guard let Json::Object(obj) = json else {
    #|    return Err("Expected object for User")
    #|  }
    #|  let tags : Array[String] = match obj["tags"] {
    #|    Some(v) => {
    #|      match parse_array(v, fn(item) { parse_string(item) }) {
    #|        Ok(parsed) => {
    #|          parsed
    #|        }
    #|        Err(e) => return Err("tags: " + e)
    #|      }
    #|    }
    #|    None => return Err("Missing field: tags")
    #|  }
    #|  Ok({ tags })
    #|}
    #|
  inspect(code, content=expected)
}

///|
test "snapshot: struct serializer with array" {
  let user = @ir.Struct::new("User")
    .with_field(@ir.Field::new("tags", @ir.Type::array(@ir.Type::string())))
  let code = ZodEmitter::new().emit_struct_serializer(user)
  let expected =
    #|///|
    #|/// Serialize User to JSON
    #|pub fn User::to_json(self : User) -> Json {
    #|  let obj : Map[String, Json] = {}
    #|  obj["tags"] = Json::Array(self.tags.map(fn(item) { Json::String(item) }))
    #|  Json::Object(obj)
    #|}
    #|
  inspect(code, content=expected)
}

