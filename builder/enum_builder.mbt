///|
/// Fluent builder for Enum

///|
pub struct EnumBuilder {
  name : String
  variants : Array[@ir.Variant]
  mut doc : String?
  mut visibility : @ir.Visibility
  type_params : Array[String]
  derives_list : Array[String]
}

///|
pub fn EnumBuilder::new(name : String) -> EnumBuilder {
  {
    name,
    variants: [],
    doc: None,
    visibility: @ir.Visibility::public(),
    type_params: [],
    derives_list: [],
  }
}

///|
pub fn EnumBuilder::with_doc(self : EnumBuilder, doc : String) -> EnumBuilder {
  self.doc = Some(doc)
  self
}

///|
pub fn EnumBuilder::with_visibility(
  self : EnumBuilder,
  vis : @ir.Visibility,
) -> EnumBuilder {
  self.visibility = vis
  self
}

///|
pub fn EnumBuilder::add_type_param(
  self : EnumBuilder,
  name : String,
) -> EnumBuilder {
  self.type_params.push(name)
  self
}

///|
pub fn EnumBuilder::add_derive(
  self : EnumBuilder,
  trait_name : String,
) -> EnumBuilder {
  self.derives_list.push(trait_name)
  self
}

///|
pub fn EnumBuilder::add_variant(
  self : EnumBuilder,
  name : String,
) -> EnumBuilder {
  self.variants.push(@ir.Variant::new(name))
  self
}

///|
pub fn EnumBuilder::add_variant_tuple(
  self : EnumBuilder,
  name : String,
  types : Array[@ir.Type],
) -> EnumBuilder {
  self.variants.push(@ir.Variant::new(name).with_tuple(types))
  self
}

///|
pub fn EnumBuilder::add_variant_struct(
  self : EnumBuilder,
  name : String,
  fields : Array[@ir.Field],
) -> EnumBuilder {
  self.variants.push(@ir.Variant::new(name).with_struct(fields))
  self
}

///|
pub fn EnumBuilder::add_variant_with(
  self : EnumBuilder,
  variant : @ir.Variant,
) -> EnumBuilder {
  self.variants.push(variant)
  self
}

///|
pub fn EnumBuilder::build(self : EnumBuilder) -> @ir.Enum {
  @ir.Enum::new(self.name)
  .with_variants(self.variants)
  .with_visibility(self.visibility)
  .with_type_params(self.type_params)
  .with_derives(self.derives_list)
  |> e => {
    match self.doc {
      Some(d) => e.with_doc(d)
      None => e
    }
  }
}
