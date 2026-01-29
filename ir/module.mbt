///|
/// Module representation - a collection of top-level items

///|
pub enum TopLevel {
  Struct(Struct)
  Enum(Enum)
  Function(Function)
  Const(ConstDecl)
  TypeAlias(TypeAlias)
  Trait(Trait)
  Impl(Impl)
}

///|
pub fn TopLevel::struct_(s : Struct) -> TopLevel {
  Struct(s)
}

///|
pub fn TopLevel::enum_(e : Enum) -> TopLevel {
  Enum(e)
}

///|
pub fn TopLevel::function(f : Function) -> TopLevel {
  Function(f)
}

///|
pub fn TopLevel::const_(c : ConstDecl) -> TopLevel {
  Const(c)
}

///|
pub fn TopLevel::type_alias(t : TypeAlias) -> TopLevel {
  TypeAlias(t)
}

///|
pub fn TopLevel::trait_(t : Trait) -> TopLevel {
  Trait(t)
}

///|
pub fn TopLevel::impl_(i : Impl) -> TopLevel {
  Impl(i)
}

///|
pub struct ConstDecl {
  name : String
  ty : Type?
  value : String // Expression as string
  doc : String?
  visibility : Visibility
}

///|
pub fn ConstDecl::new(name : String, value : String) -> ConstDecl {
  { name, ty: None, value, doc: None, visibility: Public }
}

///|
pub fn ConstDecl::with_type(self : ConstDecl, ty : Type) -> ConstDecl {
  { ..self, ty: Some(ty) }
}

///|
pub fn ConstDecl::with_doc(self : ConstDecl, doc : String) -> ConstDecl {
  { ..self, doc: Some(doc) }
}

///|
pub fn ConstDecl::with_visibility(
  self : ConstDecl,
  vis : Visibility,
) -> ConstDecl {
  { ..self, visibility: vis }
}

///|
pub struct TypeAlias {
  name : String
  target : Type
  doc : String?
  visibility : Visibility
  type_params : Array[String]
}

///|
pub fn TypeAlias::new(name : String, target : Type) -> TypeAlias {
  { name, target, doc: None, visibility: Public, type_params: [] }
}

///|
pub fn TypeAlias::with_doc(self : TypeAlias, doc : String) -> TypeAlias {
  { ..self, doc: Some(doc) }
}

///|
pub fn TypeAlias::with_visibility(
  self : TypeAlias,
  vis : Visibility,
) -> TypeAlias {
  { ..self, visibility: vis }
}

///|
pub fn TypeAlias::with_type_params(
  self : TypeAlias,
  params : Array[String],
) -> TypeAlias {
  { ..self, type_params: params }
}

///|
pub struct Trait {
  name : String
  methods : Array[Function]
  doc : String?
  visibility : Visibility
  type_params : Array[String]
  super_traits : Array[String]
}

///|
pub fn Trait::new(name : String) -> Trait {
  {
    name,
    methods: [],
    doc: None,
    visibility: Public,
    type_params: [],
    super_traits: [],
  }
}

///|
pub fn Trait::with_method(self : Trait, func : Function) -> Trait {
  let methods = self.methods.copy()
  methods.push(func)
  { ..self, methods, }
}

///|
pub fn Trait::with_doc(self : Trait, doc : String) -> Trait {
  { ..self, doc: Some(doc) }
}

///|
pub fn Trait::with_super(self : Trait, super_trait : String) -> Trait {
  let super_traits = self.super_traits.copy()
  super_traits.push(super_trait)
  { ..self, super_traits, }
}

///|
pub struct Impl {
  trait_name : String? // None for inherent impl
  type_name : String
  methods : Array[Function]
  type_params : Array[String]
}

///|
pub fn Impl::new(type_name : String) -> Impl {
  { trait_name: None, type_name, methods: [], type_params: [] }
}

///|
pub fn Impl::for_trait(self : Impl, trait_name : String) -> Impl {
  { ..self, trait_name: Some(trait_name) }
}

///|
pub fn Impl::with_method(self : Impl, func : Function) -> Impl {
  let methods = self.methods.copy()
  methods.push(func)
  { ..self, methods, }
}

///|
pub struct Module {
  name : String?
  items : Array[TopLevel]
  imports : Array[Import]
}

///|
pub struct Import {
  path : String
  as_name : String?
}

///|
pub fn Import::new(path : String) -> Import {
  { path, as_name: None }
}

///|
pub fn Import::with_alias(self : Import, name : String) -> Import {
  { ..self, as_name: Some(name) }
}

///|
pub fn Module::new() -> Module {
  { name: None, items: [], imports: [] }
}

///|
pub fn Module::with_name(self : Module, name : String) -> Module {
  { ..self, name: Some(name) }
}

///|
pub fn Module::add(self : Module, item : TopLevel) -> Module {
  let items = self.items.copy()
  items.push(item)
  { ..self, items, }
}

///|
pub fn Module::add_struct(self : Module, s : Struct) -> Module {
  self.add(Struct(s))
}

///|
pub fn Module::add_enum(self : Module, e : Enum) -> Module {
  self.add(Enum(e))
}

///|
pub fn Module::add_function(self : Module, f : Function) -> Module {
  self.add(Function(f))
}

///|
pub fn Module::add_const(self : Module, c : ConstDecl) -> Module {
  self.add(Const(c))
}

///|
pub fn Module::add_type_alias(self : Module, t : TypeAlias) -> Module {
  self.add(TypeAlias(t))
}

///|
pub fn Module::add_trait(self : Module, t : Trait) -> Module {
  self.add(Trait(t))
}

///|
pub fn Module::add_impl(self : Module, i : Impl) -> Module {
  self.add(Impl(i))
}

///|
pub fn Module::with_import(self : Module, path : String) -> Module {
  let imports = self.imports.copy()
  imports.push({ path, as_name: None })
  { ..self, imports, }
}

///|
pub fn Module::with_import_as(
  self : Module,
  path : String,
  as_name : String,
) -> Module {
  let imports = self.imports.copy()
  imports.push({ path, as_name: Some(as_name) })
  { ..self, imports, }
}
