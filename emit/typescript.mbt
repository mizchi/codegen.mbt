///|
/// TypeScript definition (.ts/.d.ts) emitter

///|
pub struct TsEmitter {
  indent_size : Int
  use_readonly : Bool // Use readonly modifier for non-mutable fields
  export_all : Bool // Add export keyword to all declarations
}

///|
pub fn TsEmitter::new() -> TsEmitter {
  { indent_size: 2, use_readonly: true, export_all: true }
}

///|
pub fn TsEmitter::without_exports(self : TsEmitter) -> TsEmitter {
  { ..self, export_all: false }
}

///|
pub fn TsEmitter::without_readonly(self : TsEmitter) -> TsEmitter {
  { ..self, use_readonly: false }
}

///|
pub fn TsEmitter::emit_struct(self : TsEmitter, s : @ir.Struct) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_to(buf, s)
  buf.to_string()
}

///|
fn TsEmitter::emit_struct_to(
  self : TsEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  // JSDoc comment
  match s.doc {
    Some(doc) => {
      buf.write_string("/**\n")
      buf.write_string(" * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }
  // Export and interface declaration
  if self.export_all {
    buf.write_string("export ")
  }
  buf.write_string("interface ")
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
fn TsEmitter::emit_field_to(
  self : TsEmitter,
  buf : StringBuilder,
  field : @ir.Field,
) -> Unit {
  self.write_indent(buf, 1)
  // Readonly modifier
  if self.use_readonly && not(field.is_mutable) {
    buf.write_string("readonly ")
  }
  // Field name (convert to camelCase)
  buf.write_string(@utils.to_camel_case(field.name))
  // Optional marker
  let is_optional = match field.ty {
    @ir.Type::Optional(_) => true
    _ => false
  }
  if is_optional {
    buf.write_string("?")
  }
  buf.write_string(": ")
  // Field type
  self.emit_type_to(buf, field.ty)
  buf.write_string(";\n")
}

///|
pub fn TsEmitter::emit_enum(self : TsEmitter, e : @ir.Enum) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_to(buf, e)
  buf.to_string()
}

///|
fn TsEmitter::emit_enum_to(
  self : TsEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  // JSDoc comment
  match e.doc {
    Some(doc) => {
      buf.write_string("/**\n")
      buf.write_string(" * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }
  // Check if all variants are unit (simple enum)
  let is_simple = e.variants
    .iter()
    .all(fn(v) {
      match v.payload {
        @ir.VariantPayload::None => true
        _ => false
      }
    })
  if is_simple {
    // Simple enum: use TypeScript enum
    if self.export_all {
      buf.write_string("export ")
    }
    buf.write_string("enum ")
    buf.write_string(e.name)
    buf.write_string(" {\n")
    for v in e.variants {
      self.write_indent(buf, 1)
      buf.write_string(v.name)
      buf.write_string(",\n")
    }
    buf.write_string("}\n")
  } else {
    // Complex enum: use discriminated union
    self.emit_discriminated_union_to(buf, e)
  }
}

///|
fn TsEmitter::emit_discriminated_union_to(
  self : TsEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  // Emit individual variant types
  for v in e.variants {
    if self.export_all {
      buf.write_string("export ")
    }
    buf.write_string("interface ")
    buf.write_string(e.name)
    buf.write_string(v.name)
    // Type parameters from parent enum
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
    // Discriminator field
    self.write_indent(buf, 1)
    buf.write_string("readonly type: \"")
    buf.write_string(v.name)
    buf.write_string("\";\n")
    // Payload fields
    match v.payload {
      @ir.VariantPayload::None => ()
      @ir.VariantPayload::Tuple(types) =>
        for i, ty in types {
          self.write_indent(buf, 1)
          buf.write_string("readonly value")
          buf.write_string(i.to_string())
          buf.write_string(": ")
          self.emit_type_to(buf, ty)
          buf.write_string(";\n")
        }
      @ir.VariantPayload::Struct(fields) =>
        for field in fields {
          self.write_indent(buf, 1)
          buf.write_string("readonly ")
          buf.write_string(@utils.to_camel_case(field.name))
          buf.write_string(": ")
          self.emit_type_to(buf, field.ty)
          buf.write_string(";\n")
        }
    }
    buf.write_string("}\n\n")
  }
  // Emit union type alias
  if self.export_all {
    buf.write_string("export ")
  }
  buf.write_string("type ")
  buf.write_string(e.name)
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
  buf.write_string(" =\n")
  for i, v in e.variants {
    self.write_indent(buf, 1)
    buf.write_string("| ")
    buf.write_string(e.name)
    buf.write_string(v.name)
    if e.type_params.length() > 0 {
      buf.write_string("<")
      for j, p in e.type_params {
        if j > 0 {
          buf.write_string(", ")
        }
        buf.write_string(p)
      }
      buf.write_string(">")
    }
    if i < e.variants.length() - 1 {
      buf.write_string("\n")
    } else {
      buf.write_string(";\n")
    }
  }
}

///|
pub fn TsEmitter::emit_type(self : TsEmitter, ty : @ir.Type) -> String {
  let buf = StringBuilder::new()
  self.emit_type_to(buf, ty)
  buf.to_string()
}

///|
fn TsEmitter::emit_type_to(
  self : TsEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
) -> Unit {
  match ty {
    @ir.Type::Primitive(name) => buf.write_string(primitive_to_ts(name))
    @ir.Type::Optional(inner) => {
      self.emit_type_to(buf, inner)
      buf.write_string(" | null")
    }
    @ir.Type::Array(inner) => {
      self.emit_type_to(buf, inner)
      buf.write_string("[]")
    }
    @ir.Type::Map(key, value) =>
      match key {
        @ir.Type::Primitive("String") => {
          buf.write_string("Record<string, ")
          self.emit_type_to(buf, value)
          buf.write_string(">")
        }
        @ir.Type::Primitive("Int") | @ir.Type::Primitive("Int64") => {
          buf.write_string("Record<number, ")
          self.emit_type_to(buf, value)
          buf.write_string(">")
        }
        _ => {
          buf.write_string("Map<")
          self.emit_type_to(buf, key)
          buf.write_string(", ")
          self.emit_type_to(buf, value)
          buf.write_string(">")
        }
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
      buf.write_string("(")
      for i, param in params {
        if i > 0 {
          buf.write_string(", ")
        }
        buf.write_string("arg")
        buf.write_string(i.to_string())
        buf.write_string(": ")
        self.emit_type_to(buf, param)
      }
      buf.write_string(") => ")
      self.emit_type_to(buf, ret)
    }
    @ir.Type::Tuple(types) => {
      buf.write_string("[")
      for i, t in types {
        if i > 0 {
          buf.write_string(", ")
        }
        self.emit_type_to(buf, t)
      }
      buf.write_string("]")
    }
    @ir.Type::Error(_) => buf.write_string("never") // Errors don't map cleanly to TS
  }
}

///|
pub fn TsEmitter::emit_module(self : TsEmitter, m : @ir.Module) -> String {
  let buf = StringBuilder::new()
  // Header comment
  buf.write_string("// Generated code - do not edit\n\n")
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
      _ => () // Functions, traits, impls not applicable
    }
  }
  buf.to_string()
}

///|
fn TsEmitter::emit_type_alias_to(
  self : TsEmitter,
  buf : StringBuilder,
  t : @ir.TypeAlias,
) -> Unit {
  match t.doc {
    Some(doc) => {
      buf.write_string("/**\n")
      buf.write_string(" * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }
  if self.export_all {
    buf.write_string("export ")
  }
  buf.write_string("type ")
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
fn TsEmitter::emit_const_to(
  self : TsEmitter,
  buf : StringBuilder,
  c : @ir.ConstDecl,
) -> Unit {
  match c.doc {
    Some(doc) => {
      buf.write_string("/**\n")
      buf.write_string(" * ")
      buf.write_string(doc)
      buf.write_string("\n */\n")
    }
    None => ()
  }
  if self.export_all {
    buf.write_string("export ")
  }
  buf.write_string("const ")
  buf.write_string(c.name)
  match c.ty {
    Some(ty) => {
      buf.write_string(": ")
      self.emit_type_to(buf, ty)
    }
    None => ()
  }
  buf.write_string(" = ")
  buf.write_string(ts_value(c.value))
  buf.write_string(";\n")
}

///|
fn primitive_to_ts(name : String) -> String {
  match name {
    "Bool" => "boolean"
    "Byte" | "Int" | "Int64" | "UInt" | "UInt64" | "Float" | "Double" =>
      "number"
    "String" => "string"
    "Bytes" => "Uint8Array"
    "Unit" => "void"
    _ => name // Unknown types pass through
  }
}

///|
fn ts_value(value : String) -> String {
  // Convert MoonBit literals to TS
  match value {
    "true" | "false" => value
    _ =>
      if value.has_prefix("\"") {
        value // String literal
      } else {
        value // Number or other
      }
  }
}

///|
fn TsEmitter::write_indent(
  self : TsEmitter,
  buf : StringBuilder,
  level : Int,
) -> Unit {
  for _i = 0; _i < level * self.indent_size; _i = _i + 1 {
    buf.write_string(" ")
  }
}
