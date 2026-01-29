///|
/// MoonBit source code emitter

///|
pub struct MoonBitEmitter {
  use_block_separator : Bool // Use ///| block separators
  emit_source_refs : Bool // Emit source reference comments
}

///|
pub fn MoonBitEmitter::new() -> MoonBitEmitter {
  { use_block_separator: true, emit_source_refs: false }
}

///|
pub fn MoonBitEmitter::without_separators(
  _self : MoonBitEmitter,
) -> MoonBitEmitter {
  { use_block_separator: false, emit_source_refs: false }
}

///|
pub fn MoonBitEmitter::with_source_refs(self : MoonBitEmitter) -> MoonBitEmitter {
  { ..self, emit_source_refs: true }
}

///|
pub fn MoonBitEmitter::emit_module(
  self : MoonBitEmitter,
  m : @ir.Module,
) -> String {
  let buf = StringBuilder::new()
  // Imports
  for imp in m.imports {
    match imp.as_name {
      Some(as_name) => {
        buf.write_string("import ")
        buf.write_string(imp.path)
        buf.write_string(" as ")
        buf.write_string(as_name)
        buf.write_string("\n")
      }
      None => {
        buf.write_string("import ")
        buf.write_string(imp.path)
        buf.write_string("\n")
      }
    }
  }
  if m.imports.length() > 0 {
    buf.write_string("\n")
  }
  // Items
  for i, item in m.items {
    if i > 0 {
      buf.write_string("\n")
    }
    match item {
      @ir.TopLevel::Struct(s) => self.emit_struct_to(buf, s)
      @ir.TopLevel::Enum(e) => self.emit_enum_to(buf, e)
      @ir.TopLevel::Function(f) => self.emit_function_to(buf, f)
      @ir.TopLevel::Const(c) => self.emit_const_to(buf, c)
      @ir.TopLevel::TypeAlias(t) => self.emit_type_alias_to(buf, t)
      @ir.TopLevel::Trait(t) => self.emit_trait_to(buf, t)
      @ir.TopLevel::Impl(i) => self.emit_impl_to(buf, i)
    }
  }
  buf.to_string()
}

///|
pub fn MoonBitEmitter::emit_struct(
  self : MoonBitEmitter,
  s : @ir.Struct,
) -> String {
  let buf = StringBuilder::new()
  self.emit_struct_to(buf, s)
  buf.to_string()
}

///|
fn MoonBitEmitter::emit_struct_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  s : @ir.Struct,
) -> Unit {
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  // Source reference comment
  if self.emit_source_refs {
    match s.source_ref {
      Some(src) => {
        buf.write_string("// ")
        buf.write_string(src.to_comment())
        buf.write_string("\n")
      }
      None => ()
    }
  }
  // Doc comment
  match s.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // Derive
  for d in s.derives {
    buf.write_string("#derive(")
    buf.write_string(d)
    buf.write_string(")\n")
  }
  // Visibility and declaration
  self.emit_visibility_to(buf, s.visibility)
  buf.write_string("struct ")
  buf.write_string(s.name)
  // Type parameters
  if s.type_params.length() > 0 {
    buf.write_string("[")
    for i, p in s.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string("]")
  }
  buf.write_string(" {\n")
  // Fields
  for field in s.fields {
    buf.write_string("  ")
    if field.is_mutable {
      buf.write_string("mut ")
    }
    buf.write_string(field.name)
    buf.write_string(" : ")
    self.emit_type_to(buf, field.ty)
    match field.default_value {
      Some(v) => {
        buf.write_string(" = ")
        buf.write_string(v)
      }
      None => ()
    }
    buf.write_string("\n")
  }
  buf.write_string("}\n")
}

///|
pub fn MoonBitEmitter::emit_enum(self : MoonBitEmitter, e : @ir.Enum) -> String {
  let buf = StringBuilder::new()
  self.emit_enum_to(buf, e)
  buf.to_string()
}

///|
fn MoonBitEmitter::emit_enum_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  e : @ir.Enum,
) -> Unit {
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  // Source reference comment
  if self.emit_source_refs {
    match e.source_ref {
      Some(src) => {
        buf.write_string("// ")
        buf.write_string(src.to_comment())
        buf.write_string("\n")
      }
      None => ()
    }
  }
  // Doc comment
  match e.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // Derive
  for d in e.derives {
    buf.write_string("#derive(")
    buf.write_string(d)
    buf.write_string(")\n")
  }
  // Visibility and declaration
  self.emit_visibility_to(buf, e.visibility)
  buf.write_string("enum ")
  buf.write_string(e.name)
  // Type parameters
  if e.type_params.length() > 0 {
    buf.write_string("[")
    for i, p in e.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string("]")
  }
  buf.write_string(" {\n")
  // Variants
  for variant in e.variants {
    buf.write_string("  ")
    buf.write_string(variant.name)
    match variant.payload {
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
        buf.write_string("(")
        for i, field in fields {
          if i > 0 {
            buf.write_string(", ")
          }
          buf.write_string(field.name)
          buf.write_string("~: ")
          self.emit_type_to(buf, field.ty)
        }
        buf.write_string(")")
      }
    }
    buf.write_string("\n")
  }
  buf.write_string("}\n")
}

///|
pub fn MoonBitEmitter::emit_function(
  self : MoonBitEmitter,
  f : @ir.Function,
) -> String {
  let buf = StringBuilder::new()
  self.emit_function_to(buf, f)
  buf.to_string()
}

///|
fn MoonBitEmitter::emit_function_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  f : @ir.Function,
) -> Unit {
  // Block separator
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  // Source reference comment
  if self.emit_source_refs {
    match f.source_ref {
      Some(src) => {
        buf.write_string("// ")
        buf.write_string(src.to_comment())
        buf.write_string("\n")
      }
      None => ()
    }
  }
  // Doc comment
  match f.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  // Visibility
  self.emit_visibility_to(buf, f.visibility)
  // async
  if f.is_async {
    buf.write_string("async ")
  }
  buf.write_string("fn")
  // Type parameters
  if f.type_params.length() > 0 {
    buf.write_string("[")
    for i, p in f.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string("]")
  }
  buf.write_string(" ")
  // Receiver (method)
  match f.receiver {
    Some((_name, ty)) => {
      self.emit_type_to(buf, ty)
      buf.write_string("::")
    }
    None => ()
  }
  // Name
  buf.write_string(f.name)
  buf.write_string("(")
  // Receiver parameter
  let mut param_idx = 0
  match f.receiver {
    Some((name, ty)) => {
      buf.write_string(name)
      buf.write_string(" : ")
      self.emit_type_to(buf, ty)
      param_idx = 1
    }
    None => ()
  }
  // Parameters
  for _i, param in f.params {
    if param_idx > 0 {
      buf.write_string(", ")
    }
    match param.label {
      Some(label) => {
        buf.write_string(param.name)
        buf.write_string("~")
        if label != param.name {
          buf.write_string(" as ")
          buf.write_string(label)
        }
      }
      None => buf.write_string(param.name)
    }
    buf.write_string(" : ")
    self.emit_type_to(buf, param.ty)
    match param.default_value {
      Some(v) => {
        buf.write_string(" = ")
        buf.write_string(v)
      }
      None => ()
    }
    param_idx += 1
  }
  buf.write_string(")")
  // Return type
  match f.return_type {
    @ir.Type::Primitive("Unit") => ()
    ty => {
      buf.write_string(" -> ")
      self.emit_type_to(buf, ty)
    }
  }
  // Error type
  match f.error_type {
    Some(err_ty) => {
      buf.write_string(" raise ")
      self.emit_type_to(buf, err_ty)
    }
    None => ()
  }
  // Body
  match f.body {
    Some(body) => {
      buf.write_string(" {\n")
      buf.write_string(@utils.indent(body, 1))
      buf.write_string("\n}\n")
    }
    None => buf.write_string("\n")
  }
}

///|
fn MoonBitEmitter::emit_const_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  c : @ir.ConstDecl,
) -> Unit {
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  match c.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  self.emit_visibility_to(buf, c.visibility)
  buf.write_string("let ")
  buf.write_string(c.name)
  match c.ty {
    Some(ty) => {
      buf.write_string(" : ")
      self.emit_type_to(buf, ty)
    }
    None => ()
  }
  buf.write_string(" = ")
  buf.write_string(c.value)
  buf.write_string("\n")
}

///|
fn MoonBitEmitter::emit_type_alias_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  t : @ir.TypeAlias,
) -> Unit {
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  match t.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  self.emit_visibility_to(buf, t.visibility)
  buf.write_string("typealias ")
  buf.write_string(t.name)
  if t.type_params.length() > 0 {
    buf.write_string("[")
    for i, p in t.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string("]")
  }
  buf.write_string(" = ")
  self.emit_type_to(buf, t.target)
  buf.write_string("\n")
}

///|
fn MoonBitEmitter::emit_trait_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  t : @ir.Trait,
) -> Unit {
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  match t.doc {
    Some(doc) => {
      buf.write_string("/// ")
      buf.write_string(doc)
      buf.write_string("\n")
    }
    None => ()
  }
  self.emit_visibility_to(buf, t.visibility)
  buf.write_string("trait ")
  buf.write_string(t.name)
  if t.type_params.length() > 0 {
    buf.write_string("[")
    for i, p in t.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string("]")
  }
  if t.super_traits.length() > 0 {
    buf.write_string(" : ")
    for i, s in t.super_traits {
      if i > 0 {
        buf.write_string(" + ")
      }
      buf.write_string(s)
    }
  }
  buf.write_string(" {\n")
  for m in t.methods {
    buf.write_string("  ")
    buf.write_string(m.name)
    buf.write_string("(Self")
    for param in m.params {
      buf.write_string(", ")
      buf.write_string(param.name)
      buf.write_string(": ")
      self.emit_type_to(buf, param.ty)
    }
    buf.write_string(")")
    match m.return_type {
      @ir.Type::Primitive("Unit") => ()
      ty => {
        buf.write_string(" -> ")
        self.emit_type_to(buf, ty)
      }
    }
    buf.write_string("\n")
  }
  buf.write_string("}\n")
}

///|
fn MoonBitEmitter::emit_impl_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  impl_ : @ir.Impl,
) -> Unit {
  if self.use_block_separator {
    buf.write_string("///|\n")
  }
  buf.write_string("impl")
  if impl_.type_params.length() > 0 {
    buf.write_string("[")
    for i, p in impl_.type_params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(p)
    }
    buf.write_string("]")
  }
  buf.write_string(" ")
  match impl_.trait_name {
    Some(trait_name) => {
      buf.write_string(trait_name)
      buf.write_string(" for ")
    }
    None => ()
  }
  buf.write_string(impl_.type_name)
  buf.write_string(" with ")
  // Methods
  if impl_.methods.length() == 1 {
    let m = impl_.methods[0]
    buf.write_string(m.name)
    buf.write_string("(")
    // Parameters (self is implicit)
    for i, param in m.params {
      if i > 0 {
        buf.write_string(", ")
      }
      buf.write_string(param.name)
    }
    buf.write_string(")")
    match m.body {
      Some(body) => {
        buf.write_string(" {\n")
        buf.write_string(@utils.indent(body, 1))
        buf.write_string("\n}\n")
      }
      None => buf.write_string("\n")
    }
  } else {
    buf.write_string("{\n")
    for m in impl_.methods {
      let emitter = MoonBitEmitter::new().without_separators()
      buf.write_string(@utils.indent(emitter.emit_function(m), 1))
    }
    buf.write_string("}\n")
  }
}

///|
pub fn MoonBitEmitter::emit_type(
  self : MoonBitEmitter,
  ty : @ir.Type,
) -> String {
  let buf = StringBuilder::new()
  self.emit_type_to(buf, ty)
  buf.to_string()
}

///|
fn MoonBitEmitter::emit_type_to(
  self : MoonBitEmitter,
  buf : StringBuilder,
  ty : @ir.Type,
) -> Unit {
  match ty {
    @ir.Type::Primitive(name) => buf.write_string(name)
    @ir.Type::Optional(inner) => {
      self.emit_type_to(buf, inner)
      buf.write_string("?")
    }
    @ir.Type::Array(inner) => {
      buf.write_string("Array[")
      self.emit_type_to(buf, inner)
      buf.write_string("]")
    }
    @ir.Type::Map(key, value) => {
      buf.write_string("Map[")
      self.emit_type_to(buf, key)
      buf.write_string(", ")
      self.emit_type_to(buf, value)
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
          self.emit_type_to(buf, arg)
        }
        buf.write_string("]")
      }
    @ir.Type::Function(params, ret) => {
      buf.write_string("(")
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
      buf.write_string("Error[")
      self.emit_type_to(buf, inner)
      buf.write_string("]")
    }
  }
}

///|
fn MoonBitEmitter::emit_visibility_to(
  _self : MoonBitEmitter,
  buf : StringBuilder,
  vis : @ir.Visibility,
) -> Unit {
  match vis {
    @ir.Visibility::Public => buf.write_string("pub ")
    @ir.Visibility::Private => buf.write_string("priv ")
    @ir.Visibility::ReadOnly => buf.write_string("pub(readonly) ")
    @ir.Visibility::Package(pkg) => {
      buf.write_string("pub(")
      buf.write_string(pkg)
      buf.write_string(") ")
    }
  }
}
