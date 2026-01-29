///|
/// FlatBuffers schema (.fbs) emitter

///|
pub struct FbsEmitter {
  indent_size : Int
  use_tables : Bool  // true: table (variable), false: struct (fixed)
}

///|
pub fn FbsEmitter::new() -> FbsEmitter {
  { indent_size: 2, use_tables: true }
}

///|
pub fn FbsEmitter::with_structs(self : FbsEmitter) -> FbsEmitter {
  { ..self, use_tables: false }
}

///|
pub fn FbsEmitter::emit_struct(self : FbsEmitter, s : @ir.Struct) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_to(buf, s)
  buf.to_string()
}

///|
fn FbsEmitter::emit_struct_to(self : FbsEmitter, buf : StringBuilder, s : @ir.Struct) -> Unit {
  // Doc comment
  match s.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // table or struct
  if self.use_tables {
    buf.write_string("table ")
  } else {
    buf.write_string("struct ")
  }
  buf.write_string(s.name)
  buf.write_string(" {\n")
  // Fields
  for field in s.fields {
    self.emit_field_to(buf, field)
  }
  buf.write_string("}\n")
}

///|
fn FbsEmitter::emit_field_to(self : FbsEmitter, buf : StringBuilder, field : @ir.Field) -> Unit {
  self.write_indent(buf, 1)
  buf.write_string(to_snake_case(field.name))
  buf.write_string(":")
  buf.write_string(type_to_fbs(field.ty))
  // Default value
  match field.default_value {
    Some(val) => {
      buf.write_string(" = ")
      buf.write_string(val)
    }
    None => ()
  }
  buf.write_string(";\n")
}

///|
pub fn FbsEmitter::emit_enum(self : FbsEmitter, e : @ir.Enum) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_to(buf, e)
  buf.to_string()
}

///|
fn FbsEmitter::emit_enum_to(self : FbsEmitter, buf : StringBuilder, e : @ir.Enum) -> Unit {
  // Doc comment
  match e.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // Check if all variants are unit (simple enum)
  let is_simple = e.variants.iter().all(fn(v) {
    match v.payload {
      @ir.VariantPayload::None => true
      _ => false
    }
  })
  if is_simple {
    // Simple enum: enum Status : ubyte { Active, Inactive }
    buf.write_string("enum ")
    buf.write_string(e.name)
    buf.write_string(" : ubyte {\n")
    for i, v in e.variants {
      self.write_indent(buf, 1)
      buf.write_string(v.name)
      if i < e.variants.length() - 1 {
        buf.write_string(",")
      }
      buf.write_string("\n")
    }
    buf.write_string("}\n")
  } else {
    // Union type for complex enums
    buf.write_string("union ")
    buf.write_string(e.name)
    buf.write_string(" {\n")
    for i, v in e.variants {
      self.write_indent(buf, 1)
      buf.write_string(v.name)
      if i < e.variants.length() - 1 {
        buf.write_string(",")
      }
      buf.write_string("\n")
    }
    buf.write_string("}\n")
  }
}

///|
pub fn FbsEmitter::emit_module(self : FbsEmitter, m : @ir.Module) -> String {
  let buf = StringBuilder::new()
  // Namespace from module name
  match m.name {
    Some(name) => {
      buf.write_string("namespace ")
      buf.write_string(name)
      buf.write_string(";\n\n")
    }
    None => ()
  }
  // Emit all items
  for i, item in m.items {
    if i > 0 {
      buf.write_string("\n")
    }
    match item {
      @ir.TopLevel::Struct(s) => self.emit_struct_to(buf, s)
      @ir.TopLevel::Enum(e) => self.emit_enum_to(buf, e)
      _ => () // Functions, traits etc. not applicable to FBS
    }
  }
  buf.to_string()
}

///|
fn type_to_fbs(ty : @ir.Type) -> String {
  match ty {
    @ir.Type::Primitive(name) => primitive_to_fbs(name)
    @ir.Type::Optional(inner) => type_to_fbs(inner)  // FBS handles nullability differently
    @ir.Type::Array(inner) => "[" + type_to_fbs(inner) + "]"
    @ir.Type::Named(name, _) => name
    @ir.Type::Map(_, _) => "string"  // FBS doesn't have native maps, use string/JSON
    @ir.Type::Tuple(_) => "string"   // Not directly supported
    @ir.Type::Function(_, _) => "string"  // Not applicable
    @ir.Type::Error(_) => "string"
  }
}

///|
fn primitive_to_fbs(name : String) -> String {
  match name {
    "Bool" => "bool"
    "Byte" => "ubyte"
    "Int" => "int"
    "Int64" => "long"
    "UInt" => "uint"
    "UInt64" => "ulong"
    "Float" => "float"
    "Double" => "double"
    "String" => "string"
    "Bytes" => "[ubyte]"
    _ => "string"  // Default fallback
  }
}

///|
fn to_snake_case(s : String) -> String {
  let buf = StringBuilder::new()
  for i, c in s {
    if c >= 'A' && c <= 'Z' {
      if i > 0 {
        buf.write_char('_')
      }
      buf.write_char((c.to_int() + 32).unsafe_to_char())
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
fn FbsEmitter::write_indent(self : FbsEmitter, buf : StringBuilder, level : Int) -> Unit {
  for _i = 0; _i < level * self.indent_size; _i = _i + 1 {
    buf.write_string(" ")
  }
}
