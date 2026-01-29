///|
/// JSON Schema emitter

///|
pub struct JsonSchemaEmitter {
  indent_size : Int
  schema_draft : String // e.g., "https://json-schema.org/draft/2020-12/schema"
}

///|
pub fn JsonSchemaEmitter::new() -> JsonSchemaEmitter {
  {
    indent_size: 2,
    schema_draft: "https://json-schema.org/draft/2020-12/schema",
  }
}

///|
pub fn JsonSchemaEmitter::with_indent(
  self : JsonSchemaEmitter,
  size : Int,
) -> JsonSchemaEmitter {
  { ..self, indent_size: size }
}

///|
pub fn JsonSchemaEmitter::with_draft(
  self : JsonSchemaEmitter,
  draft : String,
) -> JsonSchemaEmitter {
  { ..self, schema_draft: draft }
}

///|
pub fn JsonSchemaEmitter::emit_struct(
  self : JsonSchemaEmitter,
  s : @ir.Struct,
) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_to(buf, s)
  buf.to_string()
}

///|
fn JsonSchemaEmitter::emit_struct_to(
  self : JsonSchemaEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  buf.write_string("{\n")
  self.write_indent(buf, 1)
  buf.write_string("\"$schema\": \"")
  buf.write_string(self.schema_draft)
  buf.write_string("\",\n")
  self.write_indent(buf, 1)
  buf.write_string("\"type\": \"object\",\n")
  // Title
  self.write_indent(buf, 1)
  buf.write_string("\"title\": \"")
  buf.write_string(s.name)
  buf.write_string("\"")
  // Description
  match s.doc {
    Some(doc) => {
      buf.write_string(",\n")
      self.write_indent(buf, 1)
      buf.write_string("\"description\": \"")
      buf.write_string(escape_json_string(doc))
      buf.write_string("\"")
    }
    None => ()
  }
  // Properties
  if s.fields.length() > 0 {
    buf.write_string(",\n")
    self.write_indent(buf, 1)
    buf.write_string("\"properties\": {\n")
    for i, field in s.fields {
      if i > 0 {
        buf.write_string(",\n")
      }
      self.emit_field_to(buf, field, 2)
    }
    buf.write_string("\n")
    self.write_indent(buf, 1)
    buf.write_string("}")
    // Required fields
    let required = collect_required_fields(s.fields)
    if required.length() > 0 {
      buf.write_string(",\n")
      self.write_indent(buf, 1)
      buf.write_string("\"required\": [")
      for i, name in required {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string("\"")
        buf.write_string(name)
        buf.write_string("\"")
      }
      buf.write_string("]")
    }
  }
  buf.write_string("\n}")
}

///|
fn collect_required_fields(fields : Array[@ir.Field]) -> Array[String] {
  let required : Array[String] = []
  for field in fields {
    // Required if: has required constraint OR type is not optional
    if field.constraints.required || not(is_optional_type(field.ty)) {
      required.push(field.name)
    }
  }
  required
}

///|
fn is_optional_type(ty : @ir.Type) -> Bool {
  match ty {
    @ir.Type::Optional(_) => true
    _ => false
  }
}

///|
fn JsonSchemaEmitter::emit_field_to(
  self : JsonSchemaEmitter,
  buf : StringBuilder,
  field : @ir.Field,
  indent : Int,
) -> Unit {
  self.write_indent(buf, indent)
  buf.write_string("\"")
  buf.write_string(field.name)
  buf.write_string("\": ")
  self.emit_type_schema_to(buf, field.ty, field.constraints, field.doc, indent)
}

///|
fn JsonSchemaEmitter::emit_type_schema_to(
  self : JsonSchemaEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
  constraints : @ir.Constraints,
  doc : String?,
  indent : Int,
) -> Unit {
  buf.write_string("{\n")
  let type_name = type_to_json_schema_type(ty)
  self.write_indent(buf, indent + 1)
  buf.write_string("\"type\": ")
  buf.write_string(type_name)
  // Description
  match doc {
    Some(d) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent + 1)
      buf.write_string("\"description\": \"")
      buf.write_string(escape_json_string(d))
      buf.write_string("\"")
    }
    None => ()
  }
  // Constraints
  self.emit_constraints_to(buf, ty, constraints, indent + 1)
  buf.write_string("\n")
  self.write_indent(buf, indent)
  buf.write_string("}")
}

///|
fn JsonSchemaEmitter::emit_constraints_to(
  self : JsonSchemaEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
  c : @ir.Constraints,
  indent : Int,
) -> Unit {
  // minLength
  match c.min_length {
    Some(len) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent)
      buf.write_string("\"minLength\": ")
      buf.write_string(len.to_string())
    }
    None => ()
  }
  // maxLength
  match c.max_length {
    Some(len) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent)
      buf.write_string("\"maxLength\": ")
      buf.write_string(len.to_string())
    }
    None => ()
  }
  // minimum
  let min_val : Int64? = if c.unsigned { Some(0L) } else { c.min_value }
  match min_val {
    Some(val) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent)
      buf.write_string("\"minimum\": ")
      buf.write_string(val.to_string())
    }
    None => ()
  }
  // maximum
  match c.max_value {
    Some(val) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent)
      buf.write_string("\"maximum\": ")
      buf.write_string(val.to_string())
    }
    None => ()
  }
  // pattern
  match c.pattern {
    Some(pat) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent)
      buf.write_string("\"pattern\": \"")
      buf.write_string(escape_json_string(pat))
      buf.write_string("\"")
    }
    None => ()
  }
  // Array items
  match ty {
    @ir.Type::Array(item_ty) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent)
      buf.write_string("\"items\": ")
      self.emit_type_schema_to(
        buf,
        item_ty,
        @ir.Constraints::new(),
        None,
        indent,
      )
    }
    _ => ()
  }
}

///|
fn type_to_json_schema_type(ty : @ir.Type) -> String {
  match ty {
    @ir.Type::Primitive(name) =>
      match name {
        "Int" | "Int64" | "UInt" | "UInt64" | "Byte" => "\"integer\""
        "Float" | "Double" => "\"number\""
        "Bool" => "\"boolean\""
        "String" => "\"string\""
        "Bytes" => "\"string\"" // base64 encoded
        "Unit" => "\"null\""
        _ => "\"string\""
      }
    @ir.Type::Optional(inner) => {
      let inner_type = type_to_json_schema_type(inner)
      "[" + inner_type + ", \"null\"]"
    }
    @ir.Type::Array(_) => "\"array\""
    @ir.Type::Map(_, _) => "\"object\""
    @ir.Type::Named(_name, _) =>
      // Reference to another schema
      "\"object\"" // Simplified, could use $ref
    @ir.Type::Tuple(_) => "\"array\""
    @ir.Type::Function(_, _) => "\"null\"" // Functions not representable in JSON Schema
    @ir.Type::Error(_) => "\"object\""
  }
}

///|
fn JsonSchemaEmitter::write_indent(
  self : JsonSchemaEmitter,
  buf : StringBuilder,
  level : Int,
) -> Unit {
  for _i = 0; _i < level * self.indent_size; _i = _i + 1 {
    buf.write_string(" ")
  }
}

///|
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
pub fn JsonSchemaEmitter::emit_enum(
  self : JsonSchemaEmitter,
  e : @ir.Enum,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  self.write_indent(buf, 1)
  buf.write_string("\"$schema\": \"")
  buf.write_string(self.schema_draft)
  buf.write_string("\",\n")
  self.write_indent(buf, 1)
  buf.write_string("\"title\": \"")
  buf.write_string(e.name)
  buf.write_string("\"")
  // Description
  match e.doc {
    Some(doc) => {
      buf.write_string(",\n")
      self.write_indent(buf, 1)
      buf.write_string("\"description\": \"")
      buf.write_string(escape_json_string(doc))
      buf.write_string("\"")
    }
    None => ()
  }
  // Check if it's a simple enum (all unit variants)
  let is_simple = e.variants
    .iter()
    .all(fn(v) {
      match v.payload {
        @ir.VariantPayload::None => true
        _ => false
      }
    })
  if is_simple {
    // Simple string enum
    buf.write_string(",\n")
    self.write_indent(buf, 1)
    buf.write_string("\"type\": \"string\",\n")
    self.write_indent(buf, 1)
    buf.write_string("\"enum\": [")
    for i, v in e.variants {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string("\"")
      buf.write_string(v.name)
      buf.write_string("\"")
    }
    buf.write_string("]")
  } else {
    // Tagged union using oneOf
    buf.write_string(",\n")
    self.write_indent(buf, 1)
    buf.write_string("\"oneOf\": [\n")
    for i, v in e.variants {
      if i > 0 {
        buf.write_string(",\n")
      }
      self.emit_variant_to(buf, v, 2)
    }
    buf.write_string("\n")
    self.write_indent(buf, 1)
    buf.write_string("]")
  }
  buf.write_string("\n}")
  buf.to_string()
}

///|
fn JsonSchemaEmitter::emit_variant_to(
  self : JsonSchemaEmitter,
  buf : StringBuilder,
  v : @ir.Variant,
  indent : Int,
) -> Unit {
  self.write_indent(buf, indent)
  buf.write_string("{\n")
  self.write_indent(buf, indent + 1)
  buf.write_string("\"type\": \"object\",\n")
  self.write_indent(buf, indent + 1)
  buf.write_string("\"properties\": {\n")
  self.write_indent(buf, indent + 2)
  buf.write_string("\"type\": { \"const\": \"")
  buf.write_string(v.name)
  buf.write_string("\" }")
  match v.payload {
    @ir.VariantPayload::None => ()
    @ir.VariantPayload::Tuple(types) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent + 2)
      buf.write_string("\"value\": {\n")
      self.write_indent(buf, indent + 3)
      buf.write_string("\"type\": \"array\",\n")
      self.write_indent(buf, indent + 3)
      buf.write_string("\"items\": [\n")
      for i, ty in types {
        if i > 0 {
          buf.write_string(",\n")
        }
        self.write_indent(buf, indent + 4)
        self.emit_type_schema_to(
          buf,
          ty,
          @ir.Constraints::new(),
          None,
          indent + 4,
        )
      }
      buf.write_string("\n")
      self.write_indent(buf, indent + 3)
      buf.write_string("]\n")
      self.write_indent(buf, indent + 2)
      buf.write_string("}")
    }
    @ir.VariantPayload::Struct(fields) => {
      buf.write_string(",\n")
      self.write_indent(buf, indent + 2)
      buf.write_string("\"value\": {\n")
      self.write_indent(buf, indent + 3)
      buf.write_string("\"type\": \"object\",\n")
      self.write_indent(buf, indent + 3)
      buf.write_string("\"properties\": {\n")
      for i, field in fields {
        if i > 0 {
          buf.write_string(",\n")
        }
        self.emit_field_to(buf, field, indent + 4)
      }
      buf.write_string("\n")
      self.write_indent(buf, indent + 3)
      buf.write_string("}\n")
      self.write_indent(buf, indent + 2)
      buf.write_string("}")
    }
  }
  buf.write_string("\n")
  self.write_indent(buf, indent + 1)
  buf.write_string("},\n")
  self.write_indent(buf, indent + 1)
  buf.write_string("\"required\": [\"type\"")
  match v.payload {
    @ir.VariantPayload::None => ()
    _ => buf.write_string(", \"value\"")
  }
  buf.write_string("]\n")
  self.write_indent(buf, indent)
  buf.write_string("}")
}
