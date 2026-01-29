///|
/// Enum representation in the IR

///|
pub enum VariantPayload {
  None
  Tuple(Array[Type])
  Struct(Array[Field])
}

///|
pub struct Variant {
  name : String
  payload : VariantPayload
  doc : String?
}

///|
pub fn Variant::new(name : String) -> Variant {
  { name, payload: None, doc: None }
}

///|
pub fn Variant::with_tuple(self : Variant, types : Array[Type]) -> Variant {
  { ..self, payload: Tuple(types) }
}

///|
pub fn Variant::with_struct(self : Variant, fields : Array[Field]) -> Variant {
  { ..self, payload: Struct(fields) }
}

///|
pub fn Variant::with_doc(self : Variant, doc : String) -> Variant {
  { ..self, doc: Some(doc) }
}

///|
pub struct Enum {
  name : String
  variants : Array[Variant]
  doc : String?
  visibility : Visibility
  type_params : Array[String]
  derives : Array[String]
}

///|
pub fn Enum::new(name : String) -> Enum {
  {
    name,
    variants: [],
    doc: None,
    visibility: Public,
    type_params: [],
    derives: [],
  }
}

///|
pub fn Enum::with_variant(self : Enum, variant : Variant) -> Enum {
  let variants = self.variants.copy()
  variants.push(variant)
  { ..self, variants }
}

///|
pub fn Enum::with_variants(self : Enum, variants : Array[Variant]) -> Enum {
  let new_variants = self.variants.copy()
  for v in variants {
    new_variants.push(v)
  }
  { ..self, variants: new_variants }
}

///|
pub fn Enum::with_doc(self : Enum, doc : String) -> Enum {
  { ..self, doc: Some(doc) }
}

///|
pub fn Enum::with_visibility(self : Enum, vis : Visibility) -> Enum {
  { ..self, visibility: vis }
}

///|
pub fn Enum::with_type_params(self : Enum, params : Array[String]) -> Enum {
  { ..self, type_params: params }
}

///|
pub fn Enum::with_derives(self : Enum, traits : Array[String]) -> Enum {
  { ..self, derives: traits }
}
