///|
/// Fluent builder for Struct

///|
pub struct StructBuilder {
  name : String
  fields : Array[@ir.Field]
  mut doc : String?
  mut visibility : @ir.Visibility
  type_params : Array[String]
  derives_list : Array[String]
}

///|
pub fn StructBuilder::new(name : String) -> StructBuilder {
  {
    name,
    fields: [],
    doc: None,
    visibility: @ir.Visibility::public(),
    type_params: [],
    derives_list: [],
  }
}

///|
pub fn StructBuilder::with_doc(
  self : StructBuilder,
  doc : String,
) -> StructBuilder {
  self.doc = Some(doc)
  self
}

///|
pub fn StructBuilder::with_visibility(
  self : StructBuilder,
  vis : @ir.Visibility,
) -> StructBuilder {
  self.visibility = vis
  self
}

///|
pub fn StructBuilder::add_type_param(
  self : StructBuilder,
  name : String,
) -> StructBuilder {
  self.type_params.push(name)
  self
}

///|
pub fn StructBuilder::add_derive(
  self : StructBuilder,
  trait_name : String,
) -> StructBuilder {
  self.derives_list.push(trait_name)
  self
}

///|
pub fn StructBuilder::add_field(
  self : StructBuilder,
  name : String,
  ty : @ir.Type,
) -> StructBuilder {
  self.fields.push(@ir.Field::new(name, ty))
  self
}

///|
pub fn StructBuilder::add_field_with(
  self : StructBuilder,
  field : @ir.Field,
) -> StructBuilder {
  self.fields.push(field)
  self
}

///|
pub fn StructBuilder::add_optional_field(
  self : StructBuilder,
  name : String,
  ty : @ir.Type,
) -> StructBuilder {
  self.fields.push(@ir.Field::new(name, @ir.Type::optional(ty)))
  self
}

///|
pub fn StructBuilder::add_mutable_field(
  self : StructBuilder,
  name : String,
  ty : @ir.Type,
) -> StructBuilder {
  self.fields.push(@ir.Field::new(name, ty).as_mutable())
  self
}

///|
pub fn StructBuilder::build(self : StructBuilder) -> @ir.Struct {
  @ir.Struct::new(self.name)
  .with_fields(self.fields)
  .with_visibility(self.visibility)
  .with_type_params(self.type_params)
  .with_derives(self.derives_list)
  |> s => {
    match self.doc {
      Some(d) => s.with_doc(d)
      None => s
    }
  }
}
