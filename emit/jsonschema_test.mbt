///|
test "emit simple struct to json schema" {
  let s = @ir.Struct::new("User")
    .with_doc("A user record")
    .with_field(@ir.Field::new("id", @ir.Type::int64()))
    .with_field(@ir.Field::new("name", @ir.Type::string()).as_required())
    .with_field(@ir.Field::new("email", @ir.Type::optional(@ir.Type::string())))
  let emitter = JsonSchemaEmitter::new()
  let code = emitter.emit_struct(s)
  let expected =
    #|{
    #|  "$schema": "https://json-schema.org/draft/2020-12/schema",
    #|  "type": "object",
    #|  "title": "User",
    #|  "description": "A user record",
    #|  "properties": {
    #|    "id": {
    #|      "type": "integer"
    #|    },
    #|    "name": {
    #|      "type": "string"
    #|    },
    #|    "email": {
    #|      "type": ["string", "null"]
    #|    }
    #|  },
    #|  "required": ["id", "name"]
    #|}
  inspect(code, content=expected)
}

///|
test "emit struct with constraints to json schema" {
  let s = @ir.Struct::new("CreateUserParams")
    .with_field(
      @ir.Field::new("name", @ir.Type::string())
        .as_required()
        .with_min_length(1)
        .with_max_length(100),
    )
    .with_field(
      @ir.Field::new("age", @ir.Type::int64())
        .as_unsigned()
        .with_max_value(150L),
    )
  let emitter = JsonSchemaEmitter::new()
  let code = emitter.emit_struct(s)
  let expected =
    #|{
    #|  "$schema": "https://json-schema.org/draft/2020-12/schema",
    #|  "type": "object",
    #|  "title": "CreateUserParams",
    #|  "properties": {
    #|    "name": {
    #|      "type": "string",
    #|      "minLength": 1,
    #|      "maxLength": 100
    #|    },
    #|    "age": {
    #|      "type": "integer",
    #|      "minimum": 0,
    #|      "maximum": 150
    #|    }
    #|  },
    #|  "required": ["name", "age"]
    #|}
  inspect(code, content=expected)
}

///|
test "emit simple enum to json schema" {
  let e = @ir.Enum::new("Status")
    .with_doc("User status")
    .with_variant(@ir.Variant::new("Active"))
    .with_variant(@ir.Variant::new("Inactive"))
    .with_variant(@ir.Variant::new("Pending"))
  let emitter = JsonSchemaEmitter::new()
  let code = emitter.emit_enum(e)
  let expected =
    #|{
    #|  "$schema": "https://json-schema.org/draft/2020-12/schema",
    #|  "title": "Status",
    #|  "description": "User status",
    #|  "type": "string",
    #|  "enum": ["Active", "Inactive", "Pending"]
    #|}
  inspect(code, content=expected)
}
