///|
/// Struct (record) representation in the IR

///|
pub enum Visibility {
  Public // pub
  Private // priv
  ReadOnly // pub(readonly)
  Package(String) // pub(pkg)
}

///|
pub fn Visibility::public() -> Visibility {
  Public
}

///|
pub fn Visibility::private() -> Visibility {
  Private
}

///|
pub fn Visibility::read_only() -> Visibility {
  ReadOnly
}

///|
pub fn Visibility::pkg(pkg : String) -> Visibility {
  Package(pkg)
}

///|
impl Show for Visibility with output(self, logger) {
  match self {
    Public => logger.write_string("pub")
    Private => logger.write_string("priv")
    ReadOnly => logger.write_string("pub(readonly)")
    Package(pkg) => {
      logger.write_string("pub(")
      logger.write_string(pkg)
      logger.write_string(")")
    }
  }
}

///|
pub struct Field {
  name : String
  ty : Type
  doc : String?
  default_value : String? // Expression as string for now
  is_mutable : Bool
  constraints : Constraints
}

///|
pub fn Field::new(name : String, ty : Type) -> Field {
  {
    name,
    ty,
    doc: None,
    default_value: None,
    is_mutable: false,
    constraints: Constraints::new(),
  }
}

///|
pub fn Field::with_doc(self : Field, doc : String) -> Field {
  { ..self, doc: Some(doc) }
}

///|
pub fn Field::with_default(self : Field, value : String) -> Field {
  { ..self, default_value: Some(value) }
}

///|
pub fn Field::as_mutable(self : Field) -> Field {
  { ..self, is_mutable: true }
}

///|
pub fn Field::as_required(self : Field) -> Field {
  { ..self, constraints: self.constraints.as_required() }
}

///|
pub fn Field::with_max_length(self : Field, len : Int) -> Field {
  { ..self, constraints: self.constraints.with_max_length(len) }
}

///|
pub fn Field::with_min_length(self : Field, len : Int) -> Field {
  { ..self, constraints: self.constraints.with_min_length(len) }
}

///|
pub fn Field::with_min_value(self : Field, val : Int64) -> Field {
  { ..self, constraints: self.constraints.with_min_value(val) }
}

///|
pub fn Field::with_max_value(self : Field, val : Int64) -> Field {
  { ..self, constraints: self.constraints.with_max_value(val) }
}

///|
pub fn Field::with_pattern(self : Field, pat : String) -> Field {
  { ..self, constraints: self.constraints.with_pattern(pat) }
}

///|
pub fn Field::as_unsigned(self : Field) -> Field {
  { ..self, constraints: self.constraints.as_unsigned() }
}

///|
pub fn Field::with_constraints(self : Field, c : Constraints) -> Field {
  { ..self, constraints: c }
}

///|
pub struct Struct {
  name : String
  fields : Array[Field]
  doc : String?
  visibility : Visibility
  type_params : Array[String]
  derives : Array[String]
}

///|
pub fn Struct::new(name : String) -> Struct {
  {
    name,
    fields: [],
    doc: None,
    visibility: Public,
    type_params: [],
    derives: [],
  }
}

///|
pub fn Struct::with_field(self : Struct, field : Field) -> Struct {
  let fields = self.fields.copy()
  fields.push(field)
  { ..self, fields, }
}

///|
pub fn Struct::with_fields(self : Struct, fields : Array[Field]) -> Struct {
  let new_fields = self.fields.copy()
  for f in fields {
    new_fields.push(f)
  }
  { ..self, fields: new_fields }
}

///|
pub fn Struct::with_doc(self : Struct, doc : String) -> Struct {
  { ..self, doc: Some(doc) }
}

///|
pub fn Struct::with_visibility(self : Struct, vis : Visibility) -> Struct {
  { ..self, visibility: vis }
}

///|
pub fn Struct::with_type_params(
  self : Struct,
  params : Array[String],
) -> Struct {
  { ..self, type_params: params }
}

///|
pub fn Struct::with_derives(self : Struct, traits : Array[String]) -> Struct {
  { ..self, derives: traits }
}
