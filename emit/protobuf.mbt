///|
/// Protocol Buffers schema (.proto) emitter

///|
pub struct ProtoEmitter {
  indent_size : Int
  proto_version : String // "proto3" or "proto2"
}

///|
pub fn ProtoEmitter::new() -> ProtoEmitter {
  { indent_size: 2, proto_version: "proto3" }
}

///|
pub fn ProtoEmitter::proto2(self : ProtoEmitter) -> ProtoEmitter {
  { ..self, proto_version: "proto2" }
}

///|
pub fn ProtoEmitter::emit_struct(self : ProtoEmitter, s : @ir.Struct) -> String {
  let buf = StringBuilder::new()
  self.emit_message_to(buf, s, 1)
  buf.to_string()
}

///|
fn ProtoEmitter::emit_message_to(
  self : ProtoEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
  start_field_num : Int,
) -> Unit {
  // Comment
  match s.doc {
    Some(doc) => {
      buf.write_string("// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  buf.write_string("message ")
  buf.write_string(s.name)
  buf.write_string(" {\n")
  // Fields with auto-incrementing field numbers
  let mut field_num = start_field_num
  for field in s.fields {
    self.emit_field_to(buf, field, field_num)
    field_num += 1
  }
  buf.write_string("}\n")
}

///|
fn ProtoEmitter::emit_field_to(
  self : ProtoEmitter,
  buf : StringBuilder,
  field : @ir.Field,
  field_num : Int,
) -> Unit {
  self.write_indent(buf, 1)
  // Field modifier
  let (modifier, inner_ty) = match field.ty {
    @ir.Type::Optional(inner) => ("optional ", inner)
    @ir.Type::Array(inner) => ("repeated ", inner)
    ty => ("", ty)
  }
  buf.write_string(modifier)
  buf.write_string(type_to_proto(inner_ty))
  buf.write_string(" ")
  buf.write_string(@utils.to_snake_case(field.name))
  buf.write_string(" = ")
  buf.write_string(field_num.to_string())
  buf.write_string(";\n")
}

///|
pub fn ProtoEmitter::emit_enum(self : ProtoEmitter, e : @ir.Enum) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_to(buf, e)
  buf.to_string()
}

///|
fn ProtoEmitter::emit_enum_to(
  self : ProtoEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  // Comment
  match e.doc {
    Some(doc) => {
      buf.write_string("// ")
      buf.write_string(doc)
      buf.write_string("\n")
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
    // Simple enum
    buf.write_string("enum ")
    buf.write_string(e.name)
    buf.write_string(" {\n")
    // Proto3 requires first value to be 0
    for i, v in e.variants {
      self.write_indent(buf, 1)
      buf.write_string(@utils.to_snake_case(v.name).to_upper())
      buf.write_string(" = ")
      buf.write_string(i.to_string())
      buf.write_string(";\n")
    }
    buf.write_string("}\n")
  } else {
    // Complex enum: use oneof in a wrapper message
    buf.write_string("message ")
    buf.write_string(e.name)
    buf.write_string(" {\n")
    self.write_indent(buf, 1)
    buf.write_string("oneof variant {\n")
    for i, v in e.variants {
      self.emit_variant_to(buf, e.name, v, i + 1)
    }
    self.write_indent(buf, 1)
    buf.write_string("}\n")
    buf.write_string("}\n")
    // Emit nested message types for variants with payloads
    for v in e.variants {
      match v.payload {
        @ir.VariantPayload::None => ()
        @ir.VariantPayload::Tuple(types) => {
          buf.write_string("\nmessage ")
          buf.write_string(e.name)
          buf.write_string(v.name)
          buf.write_string(" {\n")
          for j, ty in types {
            self.write_indent(buf, 1)
            buf.write_string(type_to_proto(ty))
            buf.write_string(" value")
            buf.write_string(j.to_string())
            buf.write_string(" = ")
            buf.write_string((j + 1).to_string())
            buf.write_string(";\n")
          }
          buf.write_string("}\n")
        }
        @ir.VariantPayload::Struct(fields) => {
          buf.write_string("\nmessage ")
          buf.write_string(e.name)
          buf.write_string(v.name)
          buf.write_string(" {\n")
          for j, field in fields {
            self.write_indent(buf, 1)
            buf.write_string(type_to_proto(field.ty))
            buf.write_string(" ")
            buf.write_string(@utils.to_snake_case(field.name))
            buf.write_string(" = ")
            buf.write_string((j + 1).to_string())
            buf.write_string(";\n")
          }
          buf.write_string("}\n")
        }
      }
    }
  }
}

///|
fn ProtoEmitter::emit_variant_to(
  self : ProtoEmitter,
  buf : StringBuilder,
  enum_name : String,
  v : @ir.Variant,
  field_num : Int,
) -> Unit {
  self.write_indent(buf, 2)
  match v.payload {
    @ir.VariantPayload::None => {
      // Unit variant: use bool as placeholder
      buf.write_string("bool ")
      buf.write_string(@utils.to_snake_case(v.name))
    }
    _ => {
      // Reference the nested message type
      buf.write_string(enum_name)
      buf.write_string(v.name)
      buf.write_string(" ")
      buf.write_string(@utils.to_snake_case(v.name))
    }
  }
  buf.write_string(" = ")
  buf.write_string(field_num.to_string())
  buf.write_string(";\n")
}

///|
pub fn ProtoEmitter::emit_module(self : ProtoEmitter, m : @ir.Module) -> String {
  let buf = StringBuilder::new()
  // Syntax declaration
  buf.write_string("syntax = \"")
  buf.write_string(self.proto_version)
  buf.write_string("\";\n\n")
  // Package from module name
  match m.name {
    Some(name) => {
      buf.write_string("package ")
      buf.write_string(name.replace(old="/", new="."))
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
      @ir.TopLevel::Struct(s) => self.emit_message_to(buf, s, 1)
      @ir.TopLevel::Enum(e) => self.emit_enum_to(buf, e)
      _ => () // Functions, traits etc. not applicable to proto
    }
  }
  buf.to_string()
}

///|
fn type_to_proto(ty : @ir.Type) -> String {
  match ty {
    @ir.Type::Primitive(name) => primitive_to_proto(name)
    @ir.Type::Optional(inner) => type_to_proto(inner)
    @ir.Type::Array(inner) => type_to_proto(inner) // repeated handled at field level
    @ir.Type::Named(name, _) => name
    @ir.Type::Map(key, value) =>
      "map<" + type_to_proto(key) + ", " + type_to_proto(value) + ">"
    @ir.Type::Tuple(_) => "bytes" // Not directly supported
    @ir.Type::Function(_, _) => "bytes" // Not applicable
    @ir.Type::Error(_) => "bytes"
  }
}

///|
fn primitive_to_proto(name : String) -> String {
  match name {
    "Bool" => "bool"
    "Byte" => "bytes"
    "Int" => "int32"
    "Int64" => "int64"
    "UInt" => "uint32"
    "UInt64" => "uint64"
    "Float" => "float"
    "Double" => "double"
    "String" => "string"
    "Bytes" => "bytes"
    "Unit" => "google.protobuf.Empty"
    _ => "bytes" // Default fallback
  }
}

///|
fn ProtoEmitter::write_indent(
  self : ProtoEmitter,
  buf : StringBuilder,
  level : Int,
) -> Unit {
  for _i = 0; _i < level * self.indent_size; _i = _i + 1 {
    buf.write_string(" ")
  }
}
