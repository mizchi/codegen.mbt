///|
/// Zod-style schema emitter - generates MoonBit JSON parsers with validation

///|
pub struct ZodEmitter {
  use_block_separator : Bool
}

///|
pub fn ZodEmitter::new() -> ZodEmitter {
  { use_block_separator: true }
}

///|
pub fn ZodEmitter::without_separators(_self : ZodEmitter) -> ZodEmitter {
  { use_block_separator: false }
}

///|
/// Generate from_json parser with validation for a struct
pub fn ZodEmitter::emit_struct_parser(
  self : ZodEmitter,
  s : @ir.Struct,
) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_parser_to(buf, s)
  buf.to_string()
}

///|
fn ZodEmitter::emit_struct_parser_to(
  self : ZodEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  // Doc comment
  buf.write_string("/// Parse ")
  buf.write_string(s.name)
  buf.write_string(" from JSON with validation\n")
  // Function signature
  buf.write_string("pub fn ")
  buf.write_string(s.name)
  buf.write_string("::from_json(json : Json) -> Result[")
  buf.write_string(s.name)
  buf.write_string(", String] {\n")
  // Extract object
  buf.write_string("  guard let Json::Object(obj) = json else {\n")
  buf.write_string("    return Err(\"Expected object for ")
  buf.write_string(s.name)
  buf.write_string("\")\n")
  buf.write_string("  }\n")
  // Parse each field
  for field in s.fields {
    self.emit_field_parser(buf, field)
  }
  // Construct result
  buf.write_string("  Ok({ ")
  for i, field in s.fields {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(field.name)
  }
  buf.write_string(" })\n")
  buf.write_string("}\n")
}

///|
fn ZodEmitter::emit_field_parser(
  self : ZodEmitter,
  buf : StringBuilder,
  field : @ir.Field,
) -> Unit {
  let name = field.name
  let is_optional = match field.ty {
    @ir.Type::Optional(_) => true
    _ => false
  }
  let inner_ty = match field.ty {
    @ir.Type::Optional(inner) => inner
    ty => ty
  }
  if is_optional {
    // Optional field
    buf.write_string("  let ")
    buf.write_string(name)
    buf.write_string(" : ")
    self.emit_moonbit_type(buf, field.ty)
    buf.write_string(" = match obj[\"")
    buf.write_string(name)
    buf.write_string("\"] {\n")
    buf.write_string("    Some(v) => {\n")
    buf.write_string("      guard let Json::Null != v else { None }\n")
    buf.write_string("      match ")
    self.emit_json_extractor(buf, inner_ty, "v")
    buf.write_string(" {\n")
    buf.write_string("        Ok(parsed) => {\n")
    // Validation for optional
    self.emit_field_validation_inline(buf, field, "parsed", "          ")
    buf.write_string("          Some(parsed)\n")
    buf.write_string("        }\n")
    buf.write_string("        Err(e) => return Err(\"")
    buf.write_string(name)
    buf.write_string(": \" + e)\n")
    buf.write_string("      }\n")
    buf.write_string("    }\n")
    buf.write_string("    None => None\n")
    buf.write_string("  }\n")
  } else {
    // Required field
    buf.write_string("  let ")
    buf.write_string(name)
    buf.write_string(" : ")
    self.emit_moonbit_type(buf, field.ty)
    buf.write_string(" = match obj[\"")
    buf.write_string(name)
    buf.write_string("\"] {\n")
    buf.write_string("    Some(v) => {\n")
    buf.write_string("      match ")
    self.emit_json_extractor(buf, field.ty, "v")
    buf.write_string(" {\n")
    buf.write_string("        Ok(parsed) => {\n")
    // Validation
    self.emit_field_validation_inline(buf, field, "parsed", "          ")
    buf.write_string("          parsed\n")
    buf.write_string("        }\n")
    buf.write_string("        Err(e) => return Err(\"")
    buf.write_string(name)
    buf.write_string(": \" + e)\n")
    buf.write_string("      }\n")
    buf.write_string("    }\n")
    // Check if field is required
    if field.constraints.required {
      buf.write_string("    None => return Err(\"")
      buf.write_string(name)
      buf.write_string(" is required\")\n")
    } else {
      buf.write_string("    None => return Err(\"Missing field: ")
      buf.write_string(name)
      buf.write_string("\")\n")
    }
    buf.write_string("  }\n")
  }
}

///|
fn ZodEmitter::emit_json_extractor(
  self : ZodEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
  var_name : String,
) -> Unit {
  match ty {
    @ir.Type::Primitive(name) => {
      buf.write_string("parse_")
      buf.write_string(name.to_lower())
      buf.write_string("(")
      buf.write_string(var_name)
      buf.write_string(")")
    }
    @ir.Type::Array(inner) => {
      buf.write_string("parse_array(")
      buf.write_string(var_name)
      buf.write_string(", fn(item) { ")
      self.emit_json_extractor(buf, inner, "item")
      buf.write_string(" })")
    }
    @ir.Type::Optional(inner) => self.emit_json_extractor(buf, inner, var_name)
    @ir.Type::Named(name, _) => {
      buf.write_string(name)
      buf.write_string("::from_json(")
      buf.write_string(var_name)
      buf.write_string(")")
    }
    @ir.Type::Map(_, value) => {
      buf.write_string("parse_map(")
      buf.write_string(var_name)
      buf.write_string(", fn(item) { ")
      self.emit_json_extractor(buf, value, "item")
      buf.write_string(" })")
    }
    _ => buf.write_string("Err(\"Unsupported type\")")
  }
}

///|
fn ZodEmitter::emit_field_validation_inline(
  _self : ZodEmitter,
  buf : StringBuilder,
  field : @ir.Field,
  var_name : String,
  indent : String,
) -> Unit {
  let c = field.constraints
  let name = field.name
  let is_string = is_string_type(field.ty)
  let is_numeric = is_numeric_type(field.ty)
  // Required validation for strings (empty check)
  if c.required && is_string {
    buf.write_string(indent)
    buf.write_string("if ")
    buf.write_string(var_name)
    buf.write_string(".length() == 0 {\n")
    buf.write_string(indent)
    buf.write_string("  return Err(\"")
    buf.write_string(name)
    buf.write_string(" cannot be empty\")\n")
    buf.write_string(indent)
    buf.write_string("}\n")
  }
  // min_length
  match c.min_length {
    Some(len) =>
      if is_string {
        buf.write_string(indent)
        buf.write_string("if ")
        buf.write_string(var_name)
        buf.write_string(".length() < ")
        buf.write_string(len.to_string())
        buf.write_string(" {\n")
        buf.write_string(indent)
        buf.write_string("  return Err(\"")
        buf.write_string(name)
        buf.write_string(" must be at least ")
        buf.write_string(len.to_string())
        buf.write_string(" characters\")\n")
        buf.write_string(indent)
        buf.write_string("}\n")
      }
    None => ()
  }
  // max_length
  match c.max_length {
    Some(len) =>
      if is_string {
        buf.write_string(indent)
        buf.write_string("if ")
        buf.write_string(var_name)
        buf.write_string(".length() > ")
        buf.write_string(len.to_string())
        buf.write_string(" {\n")
        buf.write_string(indent)
        buf.write_string("  return Err(\"")
        buf.write_string(name)
        buf.write_string(" must be at most ")
        buf.write_string(len.to_string())
        buf.write_string(" characters\")\n")
        buf.write_string(indent)
        buf.write_string("}\n")
      }
    None => ()
  }
  // unsigned
  if c.unsigned && is_numeric {
    buf.write_string(indent)
    buf.write_string("if ")
    buf.write_string(var_name)
    buf.write_string(" < 0L {\n")
    buf.write_string(indent)
    buf.write_string("  return Err(\"")
    buf.write_string(name)
    buf.write_string(" must be non-negative\")\n")
    buf.write_string(indent)
    buf.write_string("}\n")
  }
  // min_value
  match c.min_value {
    Some(val) =>
      if is_numeric {
        buf.write_string(indent)
        buf.write_string("if ")
        buf.write_string(var_name)
        buf.write_string(" < ")
        buf.write_string(val.to_string())
        buf.write_string("L {\n")
        buf.write_string(indent)
        buf.write_string("  return Err(\"")
        buf.write_string(name)
        buf.write_string(" must be at least ")
        buf.write_string(val.to_string())
        buf.write_string("\")\n")
        buf.write_string(indent)
        buf.write_string("}\n")
      }
    None => ()
  }
  // max_value
  match c.max_value {
    Some(val) =>
      if is_numeric {
        buf.write_string(indent)
        buf.write_string("if ")
        buf.write_string(var_name)
        buf.write_string(" > ")
        buf.write_string(val.to_string())
        buf.write_string("L {\n")
        buf.write_string(indent)
        buf.write_string("  return Err(\"")
        buf.write_string(name)
        buf.write_string(" must be at most ")
        buf.write_string(val.to_string())
        buf.write_string("\")\n")
        buf.write_string(indent)
        buf.write_string("}\n")
      }
    None => ()
  }
}

///|
fn ZodEmitter::emit_moonbit_type(
  self : ZodEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
) -> Unit {
  match ty {
    @ir.Type::Primitive(name) => buf.write_string(name)
    @ir.Type::Optional(inner) => {
      self.emit_moonbit_type(buf, inner)
      buf.write_string("?")
    }
    @ir.Type::Array(inner) => {
      buf.write_string("Array[")
      self.emit_moonbit_type(buf, inner)
      buf.write_string("]")
    }
    @ir.Type::Map(key, value) => {
      buf.write_string("Map[")
      self.emit_moonbit_type(buf, key)
      buf.write_string(", ")
      self.emit_moonbit_type(buf, value)
      buf.write_string("]")
    }
    @ir.Type::Named(name, args) =>
      if args.is_empty() {
        buf.write_string(name)
      } else {
        buf.write_string(name)
        buf.write_string("[")
        for i, arg in args {
          if i > 0 {
            buf.write_string(", ")
          }
          self.emit_moonbit_type(buf, arg)
        }
        buf.write_string("]")
      }
    @ir.Type::Tuple(types) => {
      buf.write_string("(")
      for i, t in types {
        if i > 0 {
          buf.write_string(", ")
        }
        self.emit_moonbit_type(buf, t)
      }
      buf.write_string(")")
    }
    @ir.Type::Function(_, _) => buf.write_string("Unit") // Not supported
    @ir.Type::Error(_) => buf.write_string("Unit")
  }
}

///|
/// Generate to_json serializer for a struct
pub fn ZodEmitter::emit_struct_serializer(
  self : ZodEmitter,
  s : @ir.Struct,
) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_serializer_to(buf, s)
  buf.to_string()
}

///|
fn ZodEmitter::emit_struct_serializer_to(
  self : ZodEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  // Doc comment
  buf.write_string("/// Serialize ")
  buf.write_string(s.name)
  buf.write_string(" to JSON\n")
  // Function signature
  buf.write_string("pub fn ")
  buf.write_string(s.name)
  buf.write_string("::to_json(self : ")
  buf.write_string(s.name)
  buf.write_string(") -> Json {\n")
  buf.write_string("  let obj : Map[String, Json] = {}\n")
  // Serialize each field
  for field in s.fields {
    self.emit_field_serializer(buf, field)
  }
  buf.write_string("  Json::Object(obj)\n")
  buf.write_string("}\n")
}

///|
fn ZodEmitter::emit_field_serializer(
  self : ZodEmitter,
  buf : StringBuilder,
  field : @ir.Field,
) -> Unit {
  let name = field.name
  let is_optional = match field.ty {
    @ir.Type::Optional(_) => true
    _ => false
  }
  if is_optional {
    buf.write_string("  match self.")
    buf.write_string(name)
    buf.write_string(" {\n")
    buf.write_string("    Some(v) => obj[\"")
    buf.write_string(name)
    buf.write_string("\"] = ")
    let inner = match field.ty {
      @ir.Type::Optional(inner) => inner
      ty => ty
    }
    self.emit_value_to_json(buf, inner, "v")
    buf.write_string("\n")
    buf.write_string("    None => obj[\"")
    buf.write_string(name)
    buf.write_string("\"] = Json::Null\n")
    buf.write_string("  }\n")
  } else {
    buf.write_string("  obj[\"")
    buf.write_string(name)
    buf.write_string("\"] = ")
    self.emit_value_to_json(buf, field.ty, "self." + name)
    buf.write_string("\n")
  }
}

///|
fn ZodEmitter::emit_value_to_json(
  self : ZodEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
  expr : String,
) -> Unit {
  match ty {
    @ir.Type::Primitive(name) =>
      match name {
        "String" => {
          buf.write_string("Json::String(")
          buf.write_string(expr)
          buf.write_string(")")
        }
        "Int" | "Int64" | "UInt" | "UInt64" | "Float" | "Double" | "Byte" => {
          buf.write_string("Json::Number(")
          buf.write_string(expr)
          buf.write_string(".to_double())")
        }
        "Bool" => {
          buf.write_string("Json::Boolean(")
          buf.write_string(expr)
          buf.write_string(")")
        }
        _ => {
          buf.write_string("Json::String(")
          buf.write_string(expr)
          buf.write_string(".to_string())")
        }
      }
    @ir.Type::Array(inner) => {
      buf.write_string("Json::Array(")
      buf.write_string(expr)
      buf.write_string(".map(fn(item) { ")
      self.emit_value_to_json(buf, inner, "item")
      buf.write_string(" }))")
    }
    @ir.Type::Named(_, _) => {
      buf.write_string(expr)
      buf.write_string(".to_json()")
    }
    @ir.Type::Map(_, value) => {
      buf.write_string("Json::Object(")
      buf.write_string(expr)
      buf.write_string(".map(fn(_k, v) { ")
      self.emit_value_to_json(buf, value, "v")
      buf.write_string(" }))")
    }
    @ir.Type::Optional(inner) => self.emit_value_to_json(buf, inner, expr)
    _ => buf.write_string("Json::Null")
  }
}

///|
/// Generate both parser and serializer for a struct
pub fn ZodEmitter::emit_struct(self : ZodEmitter, s : @ir.Struct) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_parser_to(buf, s)
  buf.write_string("\n")
  self.emit_struct_serializer_to(buf, s)
  buf.to_string()
}

///|
/// Generate helper functions for primitive type parsing
pub fn ZodEmitter::emit_helpers(_self : ZodEmitter) -> String {
  let helpers =
    #|///|
    #|fn parse_string(json : Json) -> Result[String, String] {
    #|  match json {
    #|    Json::String(s) => Ok(s)
    #|    _ => Err("Expected string")
    #|  }
    #|}
    #|
    #|///|
    #|fn parse_int(json : Json) -> Result[Int, String] {
    #|  match json {
    #|    Json::Number(n) => Ok(n.to_int())
    #|    _ => Err("Expected number")
    #|  }
    #|}
    #|
    #|///|
    #|fn parse_int64(json : Json) -> Result[Int64, String] {
    #|  match json {
    #|    Json::Number(n) => Ok(n.to_int64())
    #|    _ => Err("Expected number")
    #|  }
    #|}
    #|
    #|///|
    #|fn parse_double(json : Json) -> Result[Double, String] {
    #|  match json {
    #|    Json::Number(n) => Ok(n)
    #|    _ => Err("Expected number")
    #|  }
    #|}
    #|
    #|///|
    #|fn parse_bool(json : Json) -> Result[Bool, String] {
    #|  match json {
    #|    Json::Boolean(b) => Ok(b)
    #|    _ => Err("Expected boolean")
    #|  }
    #|}
    #|
    #|///|
    #|fn parse_array[T](json : Json, parse_item : (Json) -> Result[T, String]) -> Result[Array[T], String] {
    #|  match json {
    #|    Json::Array(arr) => {
    #|      let result : Array[T] = []
    #|      for item in arr {
    #|        match parse_item(item) {
    #|          Ok(v) => result.push(v)
    #|          Err(e) => return Err(e)
    #|        }
    #|      }
    #|      Ok(result)
    #|    }
    #|    _ => Err("Expected array")
    #|  }
    #|}
    #|
    #|///|
    #|fn parse_map[V](json : Json, parse_value : (Json) -> Result[V, String]) -> Result[Map[String, V], String] {
    #|  match json {
    #|    Json::Object(obj) => {
    #|      let result : Map[String, V] = {}
    #|      for k, v in obj {
    #|        match parse_value(v) {
    #|          Ok(parsed) => result[k] = parsed
    #|          Err(e) => return Err(e)
    #|        }
    #|      }
    #|      Ok(result)
    #|    }
    #|    _ => Err("Expected object")
    #|  }
    #|}
    #|
  let buf = StringBuilder::new()
  buf.write_string(helpers)
  buf.to_string()
}

///|
/// Generate parsers and serializers for all structs in a module
pub fn ZodEmitter::emit_module(self : ZodEmitter, m : @ir.Module) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Generated JSON parsers and serializers\n\n")
  // Emit helper functions first
  buf.write_string(self.emit_helpers())
  buf.write_string("\n")
  // Emit parsers and serializers for each struct
  for item in m.items {
    match item {
      @ir.TopLevel::Struct(s) => {
        self.emit_struct_parser_to(buf, s)
        buf.write_string("\n")
        self.emit_struct_serializer_to(buf, s)
        buf.write_string("\n")
      }
      @ir.TopLevel::Enum(e) => {
        self.emit_enum_parser_to(buf, e)
        buf.write_string("\n")
        self.emit_enum_serializer_to(buf, e)
        buf.write_string("\n")
      }
      _ => ()
    }
  }
  buf.to_string()
}

///|
/// Generate from_json parser for an enum
pub fn ZodEmitter::emit_enum_parser(self : ZodEmitter, e : @ir.Enum) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_parser_to(buf, e)
  buf.to_string()
}

///|
fn ZodEmitter::emit_enum_parser_to(
  self : ZodEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  buf.write_string("/// Parse ")
  buf.write_string(e.name)
  buf.write_string(" from JSON\n")
  buf.write_string("pub fn ")
  buf.write_string(e.name)
  buf.write_string("::from_json(json : Json) -> Result[")
  buf.write_string(e.name)
  buf.write_string(", String] {\n")
  // Check if simple enum (all unit variants)
  let is_simple = e.variants
    .iter()
    .all(fn(v) {
      match v.payload {
        @ir.VariantPayload::None => true
        _ => false
      }
    })
  if is_simple {
    // Simple enum: expect string
    buf.write_string("  guard let Json::String(s) = json else {\n")
    buf.write_string("    return Err(\"Expected string for ")
    buf.write_string(e.name)
    buf.write_string("\")\n")
    buf.write_string("  }\n")
    buf.write_string("  match s {\n")
    for v in e.variants {
      buf.write_string("    \"")
      buf.write_string(v.name)
      buf.write_string("\" => Ok(")
      buf.write_string(e.name)
      buf.write_string("::")
      buf.write_string(v.name)
      buf.write_string(")\n")
    }
    buf.write_string("    _ => Err(\"Unknown variant: \" + s)\n")
    buf.write_string("  }\n")
  } else {
    // Tagged union: expect object with "type" field
    buf.write_string("  guard let Json::Object(obj) = json else {\n")
    buf.write_string("    return Err(\"Expected object for ")
    buf.write_string(e.name)
    buf.write_string("\")\n")
    buf.write_string("  }\n")
    buf.write_string(
      "  guard let Some(Json::String(tag)) = obj[\"type\"] else {\n",
    )
    buf.write_string("    return Err(\"Missing type field\")\n")
    buf.write_string("  }\n")
    buf.write_string("  match tag {\n")
    for v in e.variants {
      buf.write_string("    \"")
      buf.write_string(v.name)
      buf.write_string("\" => ")
      self.emit_variant_parser(buf, e.name, v)
      buf.write_string("\n")
    }
    buf.write_string("    _ => Err(\"Unknown variant: \" + tag)\n")
    buf.write_string("  }\n")
  }
  buf.write_string("}\n")
}

///|
fn ZodEmitter::emit_variant_parser(
  self : ZodEmitter,
  buf : StringBuilder,
  enum_name : String,
  v : @ir.Variant,
) -> Unit {
  match v.payload {
    @ir.VariantPayload::None => {
      buf.write_string("Ok(")
      buf.write_string(enum_name)
      buf.write_string("::")
      buf.write_string(v.name)
      buf.write_string(")")
    }
    @ir.VariantPayload::Tuple(types) => {
      buf.write_string("{\n")
      for i, ty in types {
        buf.write_string("      guard let Some(v")
        buf.write_string(i.to_string())
        buf.write_string("_json) = obj[\"value")
        buf.write_string(i.to_string())
        buf.write_string("\"] else {\n")
        buf.write_string("        return Err(\"Missing value")
        buf.write_string(i.to_string())
        buf.write_string("\")\n")
        buf.write_string("      }\n")
        buf.write_string("      let v")
        buf.write_string(i.to_string())
        buf.write_string(" = match ")
        self.emit_json_extractor(buf, ty, "v" + i.to_string() + "_json")
        buf.write_string(" {\n")
        buf.write_string("        Ok(v) => v\n")
        buf.write_string("        Err(e) => return Err(e)\n")
        buf.write_string("      }\n")
      }
      buf.write_string("      Ok(")
      buf.write_string(enum_name)
      buf.write_string("::")
      buf.write_string(v.name)
      buf.write_string("(")
      for i, _ in types {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string("v")
        buf.write_string(i.to_string())
      }
      buf.write_string("))\n")
      buf.write_string("    }")
    }
    @ir.VariantPayload::Struct(fields) => {
      buf.write_string("{\n")
      for field in fields {
        buf.write_string("      guard let Some(")
        buf.write_string(field.name)
        buf.write_string("_json) = obj[\"")
        buf.write_string(field.name)
        buf.write_string("\"] else {\n")
        buf.write_string("        return Err(\"Missing ")
        buf.write_string(field.name)
        buf.write_string("\")\n")
        buf.write_string("      }\n")
        buf.write_string("      let ")
        buf.write_string(field.name)
        buf.write_string(" = match ")
        self.emit_json_extractor(buf, field.ty, field.name + "_json")
        buf.write_string(" {\n")
        buf.write_string("        Ok(v) => v\n")
        buf.write_string("        Err(e) => return Err(e)\n")
        buf.write_string("      }\n")
      }
      buf.write_string("      Ok(")
      buf.write_string(enum_name)
      buf.write_string("::")
      buf.write_string(v.name)
      buf.write_string("(")
      for i, field in fields {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string(field.name)
        buf.write_string("~")
      }
      buf.write_string("))\n")
      buf.write_string("    }")
    }
  }
}

///|
/// Generate to_json serializer for an enum
pub fn ZodEmitter::emit_enum_serializer(
  self : ZodEmitter,
  e : @ir.Enum,
) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_serializer_to(buf, e)
  buf.to_string()
}

///|
fn ZodEmitter::emit_enum_serializer_to(
  self : ZodEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  buf.write_string("/// Serialize ")
  buf.write_string(e.name)
  buf.write_string(" to JSON\n")
  buf.write_string("pub fn ")
  buf.write_string(e.name)
  buf.write_string("::to_json(self : ")
  buf.write_string(e.name)
  buf.write_string(") -> Json {\n")
  let is_simple = e.variants
    .iter()
    .all(fn(v) {
      match v.payload {
        @ir.VariantPayload::None => true
        _ => false
      }
    })
  buf.write_string("  match self {\n")
  for v in e.variants {
    buf.write_string("    ")
    buf.write_string(e.name)
    buf.write_string("::")
    buf.write_string(v.name)
    match v.payload {
      @ir.VariantPayload::None =>
        if is_simple {
          buf.write_string(" => Json::String(\"")
          buf.write_string(v.name)
          buf.write_string("\")\n")
        } else {
          buf.write_string(" => {\n")
          buf.write_string("      let obj : Map[String, Json] = {}\n")
          buf.write_string("      obj[\"type\"] = Json::String(\"")
          buf.write_string(v.name)
          buf.write_string("\")\n")
          buf.write_string("      Json::Object(obj)\n")
          buf.write_string("    }\n")
        }
      @ir.VariantPayload::Tuple(types) => {
        buf.write_string("(")
        for i, _ in types {
          if i > 0 {
            buf.write_string(", ")
          }
          buf.write_string("v")
          buf.write_string(i.to_string())
        }
        buf.write_string(") => {\n")
        buf.write_string("      let obj : Map[String, Json] = {}\n")
        buf.write_string("      obj[\"type\"] = Json::String(\"")
        buf.write_string(v.name)
        buf.write_string("\")\n")
        for i, ty in types {
          buf.write_string("      obj[\"value")
          buf.write_string(i.to_string())
          buf.write_string("\"] = ")
          self.emit_value_to_json(buf, ty, "v" + i.to_string())
          buf.write_string("\n")
        }
        buf.write_string("      Json::Object(obj)\n")
        buf.write_string("    }\n")
      }
      @ir.VariantPayload::Struct(fields) => {
        buf.write_string("(")
        for i, field in fields {
          if i > 0 {
            buf.write_string(", ")
          }
          buf.write_string(field.name)
          buf.write_string("~")
        }
        buf.write_string(") => {\n")
        buf.write_string("      let obj : Map[String, Json] = {}\n")
        buf.write_string("      obj[\"type\"] = Json::String(\"")
        buf.write_string(v.name)
        buf.write_string("\")\n")
        for field in fields {
          buf.write_string("      obj[\"")
          buf.write_string(field.name)
          buf.write_string("\"] = ")
          self.emit_value_to_json(buf, field.ty, field.name)
          buf.write_string("\n")
        }
        buf.write_string("      Json::Object(obj)\n")
        buf.write_string("    }\n")
      }
    }
  }
  buf.write_string("  }\n")
  buf.write_string("}\n")
}
