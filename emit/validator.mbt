///|
/// Validator emitter - generates MoonBit validation functions

///|
pub struct ValidatorEmitter {
  use_block_separator : Bool
}

///|
pub fn ValidatorEmitter::new() -> ValidatorEmitter {
  { use_block_separator: true }
}

///|
pub fn ValidatorEmitter::without_separators(
  _self : ValidatorEmitter,
) -> ValidatorEmitter {
  { use_block_separator: false }
}

///|
pub fn ValidatorEmitter::emit_struct_validator(
  self : ValidatorEmitter,
  s : @ir.Struct,
) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_validator_to(buf, s)
  buf.to_string()
}

///|
fn ValidatorEmitter::emit_struct_validator_to(
  self : ValidatorEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  let has_validations = has_validatable_fields(s.fields)
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  // Doc comment
  buf.write_string("/// Validate ")
  buf.write_string(s.name)
  buf.write_string("\n")
  // Function signature
  buf.write_string("pub fn ")
  buf.write_string(s.name)
  if has_validations {
    buf.write_string("::validate(self : ")
  } else {
    buf.write_string("::validate(_self : ")
  }
  buf.write_string(s.name)
  buf.write_string(") -> Result[Unit, String] {\n")
  // Generate validation for each field
  for field in s.fields {
    emit_field_validation(buf, field)
  }
  buf.write_string("  Ok(())\n")
  buf.write_string("}\n")
}

///|
fn has_validatable_fields(fields : Array[@ir.Field]) -> Bool {
  for field in fields {
    if not(field.constraints.is_empty()) {
      return true
    }
  }
  false
}

///|
fn emit_field_validation(buf : StringBuilder, field : @ir.Field) -> Unit {
  let c = field.constraints
  let name = field.name
  let is_optional = match field.ty {
    @ir.Type::Optional(_) => true
    _ => false
  }
  let is_string = is_string_type(field.ty)
  let is_numeric = is_numeric_type(field.ty)
  // Required validation (for string types, check empty)
  if c.required && is_string {
    if is_optional {
      buf.write_string("  match self.")
      buf.write_string(name)
      buf.write_string(" {\n")
      buf.write_string("    Some(v) => if v.length() == 0 {\n")
      buf.write_string("      return Err(\"")
      buf.write_string(name)
      buf.write_string(" is required\")\n")
      buf.write_string("    }\n")
      buf.write_string("    None => return Err(\"")
      buf.write_string(name)
      buf.write_string(" is required\")\n")
      buf.write_string("  }\n")
    } else {
      buf.write_string("  if self.")
      buf.write_string(name)
      buf.write_string(".length() == 0 {\n")
      buf.write_string("    return Err(\"")
      buf.write_string(name)
      buf.write_string(" is required\")\n")
      buf.write_string("  }\n")
    }
  }
  // minLength validation
  match c.min_length {
    Some(len) =>
      if is_string {
        emit_length_check(buf, name, is_optional, ">=", len, "at least")
      }
    None => ()
  }
  // maxLength validation
  match c.max_length {
    Some(len) =>
      if is_string {
        emit_length_check(buf, name, is_optional, "<=", len, "at most")
      }
    None => ()
  }
  // unsigned validation
  if c.unsigned && is_numeric {
    emit_numeric_check(buf, name, is_optional, ">=", 0L, "non-negative")
  }
  // min_value validation
  match c.min_value {
    Some(val) =>
      if is_numeric {
        emit_numeric_check(
          buf,
          name,
          is_optional,
          ">=",
          val,
          "at least " + val.to_string(),
        )
      }
    None => ()
  }
  // max_value validation
  match c.max_value {
    Some(val) =>
      if is_numeric {
        emit_numeric_check(
          buf,
          name,
          is_optional,
          "<=",
          val,
          "at most " + val.to_string(),
        )
      }
    None => ()
  }
}

///|
fn emit_length_check(
  buf : StringBuilder,
  name : String,
  is_optional : Bool,
  op : String,
  len : Int,
  desc : String,
) -> Unit {
  let neg_op = if op == ">=" { "<" } else { ">" }
  if is_optional {
    buf.write_string("  match self.")
    buf.write_string(name)
    buf.write_string(" {\n")
    buf.write_string("    Some(v) => if v.length() ")
    buf.write_string(neg_op)
    buf.write_string(" ")
    buf.write_string(len.to_string())
    buf.write_string(" {\n")
    buf.write_string("      return Err(\"")
    buf.write_string(name)
    buf.write_string(" must be ")
    buf.write_string(desc)
    buf.write_string(" ")
    buf.write_string(len.to_string())
    buf.write_string(" characters\")\n")
    buf.write_string("    }\n")
    buf.write_string("    None => ()\n")
    buf.write_string("  }\n")
  } else {
    buf.write_string("  if self.")
    buf.write_string(name)
    buf.write_string(".length() ")
    buf.write_string(neg_op)
    buf.write_string(" ")
    buf.write_string(len.to_string())
    buf.write_string(" {\n")
    buf.write_string("    return Err(\"")
    buf.write_string(name)
    buf.write_string(" must be ")
    buf.write_string(desc)
    buf.write_string(" ")
    buf.write_string(len.to_string())
    buf.write_string(" characters\")\n")
    buf.write_string("  }\n")
  }
}

///|
fn emit_numeric_check(
  buf : StringBuilder,
  name : String,
  is_optional : Bool,
  op : String,
  val : Int64,
  desc : String,
) -> Unit {
  let neg_op = if op == ">=" { "<" } else { ">" }
  if is_optional {
    buf.write_string("  match self.")
    buf.write_string(name)
    buf.write_string(" {\n")
    buf.write_string("    Some(v) => if v ")
    buf.write_string(neg_op)
    buf.write_string(" ")
    buf.write_string(val.to_string())
    buf.write_string("L {\n")
    buf.write_string("      return Err(\"")
    buf.write_string(name)
    buf.write_string(" must be ")
    buf.write_string(desc)
    buf.write_string("\")\n")
    buf.write_string("    }\n")
    buf.write_string("    None => ()\n")
    buf.write_string("  }\n")
  } else {
    buf.write_string("  if self.")
    buf.write_string(name)
    buf.write_string(" ")
    buf.write_string(neg_op)
    buf.write_string(" ")
    buf.write_string(val.to_string())
    buf.write_string("L {\n")
    buf.write_string("    return Err(\"")
    buf.write_string(name)
    buf.write_string(" must be ")
    buf.write_string(desc)
    buf.write_string("\")\n")
    buf.write_string("  }\n")
  }
}

///|
fn is_string_type(ty : @ir.Type) -> Bool {
  match ty {
    @ir.Type::Primitive(name) => name == "String"
    @ir.Type::Optional(inner) => is_string_type(inner)
    _ => false
  }
}

///|
fn is_numeric_type(ty : @ir.Type) -> Bool {
  match ty {
    @ir.Type::Primitive(name) =>
      match name {
        "Int" | "Int64" | "UInt" | "UInt64" | "Float" | "Double" | "Byte" =>
          true
        _ => false
      }
    @ir.Type::Optional(inner) => is_numeric_type(inner)
    _ => false
  }
}

///|
pub fn ValidatorEmitter::emit_module_validators(
  self : ValidatorEmitter,
  m : @ir.Module,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("// Generated validators\n\n")
  for item in m.items {
    match item {
      @ir.TopLevel::Struct(s) =>
        // Only generate validator if struct has validatable fields
        if has_validatable_fields(s.fields) {
          self.emit_struct_validator_to(buf, s)
          buf.write_string("\n")
        }
      _ => ()
    }
  }
  buf.to_string()
}
