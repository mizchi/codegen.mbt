///|
/// Rust definition (.rs) emitter

///|
pub struct RustEmitter {
  indent_size : Int
  use_serde : Bool // Add serde derive macros
  use_pub : Bool // Make all fields pub
}

///|
pub fn RustEmitter::new() -> RustEmitter {
  { indent_size: 4, use_serde: true, use_pub: true }
}

///|
pub fn RustEmitter::without_serde(self : RustEmitter) -> RustEmitter {
  { ..self, use_serde: false }
}

///|
pub fn RustEmitter::with_private_fields(self : RustEmitter) -> RustEmitter {
  { ..self, use_pub: false }
}

///|
pub fn RustEmitter::emit_struct(self : RustEmitter, s : @ir.Struct) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_to(buf, s)
  buf.to_string()
}

///|
fn RustEmitter::emit_struct_to(
  self : RustEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  // Doc comment
  match s.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // Derive macros
  let derives : Array[String] = []
  derives.push("Debug")
  derives.push("Clone")
  if self.use_serde {
    derives.push("Serialize")
    derives.push("Deserialize")
  }
  // Add user-specified derives
  for d in s.derives {
    if not(derives.contains(d)) {
      derives.push(d)
    }
  }
  buf.write_string("#[derive(")
  for i, d in derives {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(d)
  }
  buf.write_string(")]\n")
  // Serde rename_all for camelCase
  if self.use_serde {
    buf.write_string("#[serde(rename_all = \"camelCase\")]\n")
  }
  // Visibility and struct declaration
  buf.write_string("pub struct ")
  buf.write_string(s.name)
  // Type parameters
  if s.type_params.length() > 0 {
    buf.write_string("<")
    for i, p in s.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string(">")
  }
  buf.write_string(" {\n")
  // Fields
  for field in s.fields {
    self.emit_field_to(buf, field)
  }
  buf.write_string("}\n")
}

///|
fn RustEmitter::emit_field_to(
  self : RustEmitter,
  buf : StringBuilder,
  field : @ir.Field,
) -> Unit {
  self.write_indent(buf, 1)
  // Pub modifier
  if self.use_pub {
    buf.write_string("pub ")
  }
  // Field name (snake_case)
  buf.write_string(@utils.to_snake_case(field.name))
  buf.write_string(": ")
  // Field type
  self.emit_type_to(buf, field.ty)
  buf.write_string(",\n")
}

///|
pub fn RustEmitter::emit_enum(self : RustEmitter, e : @ir.Enum) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_to(buf, e)
  buf.to_string()
}

///|
fn RustEmitter::emit_enum_to(
  self : RustEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  // Doc comment
  match e.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // Derive macros
  let derives : Array[String] = []
  derives.push("Debug")
  derives.push("Clone")
  if self.use_serde {
    derives.push("Serialize")
    derives.push("Deserialize")
  }
  for d in e.derives {
    if not(derives.contains(d)) {
      derives.push(d)
    }
  }
  buf.write_string("#[derive(")
  for i, d in derives {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(d)
  }
  buf.write_string(")]\n")
  // Serde tag for discriminated union
  if self.use_serde {
    buf.write_string("#[serde(tag = \"type\", rename_all = \"camelCase\")]\n")
  }
  // Enum declaration
  buf.write_string("pub enum ")
  buf.write_string(e.name)
  // Type parameters
  if e.type_params.length() > 0 {
    buf.write_string("<")
    for i, p in e.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string(">")
  }
  buf.write_string(" {\n")
  // Variants
  for v in e.variants {
    self.emit_variant_to(buf, v)
  }
  buf.write_string("}\n")
}

///|
fn RustEmitter::emit_variant_to(
  self : RustEmitter,
  buf : StringBuilder,
  v : @ir.Variant,
) -> Unit {
  self.write_indent(buf, 1)
  buf.write_string(v.name)
  match v.payload {
    @ir.VariantPayload::None => ()
    @ir.VariantPayload::Tuple(types) => {
      buf.write_string("(")
      for i, ty in types {
        if i > 0 {
          buf.write_string(", ")
        }
        self.emit_type_to(buf, ty)
      }
      buf.write_string(")")
    }
    @ir.VariantPayload::Struct(fields) => {
      buf.write_string(" {\n")
      for field in fields {
        self.write_indent(buf, 2)
        buf.write_string(@utils.to_snake_case(field.name))
        buf.write_string(": ")
        self.emit_type_to(buf, field.ty)
        buf.write_string(",\n")
      }
      self.write_indent(buf, 1)
      buf.write_string("}")
    }
  }
  buf.write_string(",\n")
}

///|
pub fn RustEmitter::emit_type(self : RustEmitter, ty : @ir.Type) -> String {
  let buf = StringBuilder::new()
  self.emit_type_to(buf, ty)
  buf.to_string()
}

///|
fn RustEmitter::emit_type_to(
  self : RustEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
) -> Unit {
  match ty {
    @ir.Type::Primitive(name) => buf.write_string(primitive_to_rust(name))
    @ir.Type::Optional(inner) => {
      buf.write_string("Option<")
      self.emit_type_to(buf, inner)
      buf.write_string(">")
    }
    @ir.Type::Array(inner) => {
      buf.write_string("Vec<")
      self.emit_type_to(buf, inner)
      buf.write_string(">")
    }
    @ir.Type::Map(key, value) => {
      buf.write_string("HashMap<")
      self.emit_type_to(buf, key)
      buf.write_string(", ")
      self.emit_type_to(buf, value)
      buf.write_string(">")
    }
    @ir.Type::Named(name, args) =>
      if args.is_empty() {
        buf.write_string(name)
      } else {
        buf.write_string(name)
        buf.write_string("<")
        for i, arg in args {
          if i > 0 {
            buf.write_string(", ")
          }
          self.emit_type_to(buf, arg)
        }
        buf.write_string(">")
      }
    @ir.Type::Function(params, ret) => {
      buf.write_string("fn(")
      for i, param in params {
        if i > 0 {
          buf.write_string(", ")
        }
        self.emit_type_to(buf, param)
      }
      buf.write_string(") -> ")
      self.emit_type_to(buf, ret)
    }
    @ir.Type::Tuple(types) => {
      buf.write_string("(")
      for i, t in types {
        if i > 0 {
          buf.write_string(", ")
        }
        self.emit_type_to(buf, t)
      }
      buf.write_string(")")
    }
    @ir.Type::Error(inner) => {
      buf.write_string("Result<(), ")
      self.emit_type_to(buf, inner)
      buf.write_string(">")
    }
  }
}

///|
pub fn RustEmitter::emit_module(self : RustEmitter, m : @ir.Module) -> String {
  let buf = StringBuilder::new()
  // Header comment
  buf.write_string("// Generated code - do not edit\n\n")
  // Imports
  if self.use_serde {
    buf.write_string("use serde::{Deserialize, Serialize};\n")
  }
  // Check if HashMap is needed
  let needs_hashmap = m.items
    .iter()
    .any(fn(item) {
      match item {
        @ir.TopLevel::Struct(s) =>
          s.fields.iter().any(fn(f) { has_map_type(f.ty) })
        _ => false
      }
    })
  if needs_hashmap {
    buf.write_string("use std::collections::HashMap;\n")
  }
  buf.write_string("\n")
  // Emit all items
  for i, item in m.items {
    if i > 0 {
      buf.write_string("\n")
    }
    match item {
      @ir.TopLevel::Struct(s) => self.emit_struct_to(buf, s)
      @ir.TopLevel::Enum(e) => self.emit_enum_to(buf, e)
      @ir.TopLevel::TypeAlias(t) => self.emit_type_alias_to(buf, t)
      @ir.TopLevel::Const(c) => self.emit_const_to(buf, c)
      _ => () // Functions, traits, impls handled differently in Rust
    }
  }
  buf.to_string()
}

///|
fn RustEmitter::emit_type_alias_to(
  self : RustEmitter,
  buf : StringBuilder,
  t : @ir.TypeAlias,
) -> Unit {
  match t.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  buf.write_string("pub type ")
  buf.write_string(t.name)
  if t.type_params.length() > 0 {
    buf.write_string("<")
    for i, p in t.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string(">")
  }
  buf.write_string(" = ")
  self.emit_type_to(buf, t.target)
  buf.write_string(";\n")
}

///|
fn RustEmitter::emit_const_to(
  self : RustEmitter,
  buf : StringBuilder,
  c : @ir.ConstDecl,
) -> Unit {
  match c.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  buf.write_string("pub const ")
  buf.write_string(c.name.to_upper())
  buf.write_string(": ")
  match c.ty {
    Some(ty) => self.emit_type_to(buf, ty)
    None => buf.write_string("&str") // Default to string
  }
  buf.write_string(" = ")
  buf.write_string(c.value)
  buf.write_string(";\n")
}

///|
fn primitive_to_rust(name : String) -> String {
  match name {
    "Bool" => "bool"
    "Byte" => "u8"
    "Int" => "i32"
    "Int64" => "i64"
    "UInt" => "u32"
    "UInt64" => "u64"
    "Float" => "f32"
    "Double" => "f64"
    "String" => "String"
    "Bytes" => "Vec<u8>"
    "Unit" => "()"
    _ => name // Unknown types pass through
  }
}

///|
fn has_map_type(ty : @ir.Type) -> Bool {
  match ty {
    @ir.Type::Map(_, _) => true
    @ir.Type::Optional(inner) => has_map_type(inner)
    @ir.Type::Array(inner) => has_map_type(inner)
    _ => false
  }
}

///|
fn RustEmitter::write_indent(
  self : RustEmitter,
  buf : StringBuilder,
  level : Int,
) -> Unit {
  for _i = 0; _i < level * self.indent_size; _i = _i + 1 {
    buf.write_string(" ")
  }
}
