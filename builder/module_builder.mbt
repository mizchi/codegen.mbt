///|
/// Fluent builder for Module

///|
pub struct ModuleBuilder {
  mut name : String?
  items : Array[@ir.TopLevel]
  imports : Array[@ir.Import]
}

///|
pub fn ModuleBuilder::new() -> ModuleBuilder {
  { name: None, items: [], imports: [] }
}

///|
pub fn ModuleBuilder::with_name(
  self : ModuleBuilder,
  name : String,
) -> ModuleBuilder {
  self.name = Some(name)
  self
}

///|
pub fn ModuleBuilder::add_import(
  self : ModuleBuilder,
  path : String,
) -> ModuleBuilder {
  self.imports.push(@ir.Import::new(path))
  self
}

///|
pub fn ModuleBuilder::add_import_as(
  self : ModuleBuilder,
  path : String,
  as_name : String,
) -> ModuleBuilder {
  self.imports.push(@ir.Import::new(path).with_alias(as_name))
  self
}

///|
pub fn ModuleBuilder::add_struct(
  self : ModuleBuilder,
  s : @ir.Struct,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::struct_(s))
  self
}

///|
pub fn ModuleBuilder::add_enum(
  self : ModuleBuilder,
  e : @ir.Enum,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::enum_(e))
  self
}

///|
pub fn ModuleBuilder::add_function(
  self : ModuleBuilder,
  f : @ir.Function,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::function(f))
  self
}

///|
pub fn ModuleBuilder::add_const(
  self : ModuleBuilder,
  c : @ir.ConstDecl,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::const_(c))
  self
}

///|
pub fn ModuleBuilder::add_type_alias(
  self : ModuleBuilder,
  t : @ir.TypeAlias,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::type_alias(t))
  self
}

///|
pub fn ModuleBuilder::add_trait(
  self : ModuleBuilder,
  t : @ir.Trait,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::trait_(t))
  self
}

///|
pub fn ModuleBuilder::add_impl(
  self : ModuleBuilder,
  i : @ir.Impl,
) -> ModuleBuilder {
  self.items.push(@ir.TopLevel::impl_(i))
  self
}

///|
pub fn ModuleBuilder::build(self : ModuleBuilder) -> @ir.Module {
  let m = @ir.Module::new()
  let m = match self.name {
    Some(n) => m.with_name(n)
    None => m
  }
  // Add imports
  let mut result = m
  for imp in self.imports {
    match imp.as_name {
      Some(name) => result = result.with_import_as(imp.path, name)
      None => result = result.with_import(imp.path)
    }
  }
  // Add items
  for item in self.items {
    result = result.add(item)
  }
  result
}
