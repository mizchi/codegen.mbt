///|
/// Function representation in the IR

///|
pub struct Param {
  name : String
  ty : Type
  label : String? // labeled parameter ~label
  default_value : String? // default value expression
}

///|
pub fn Param::new(name : String, ty : Type) -> Param {
  { name, ty, label: None, default_value: None }
}

///|
pub fn Param::with_label(self : Param, label : String) -> Param {
  { ..self, label: Some(label) }
}

///|
pub fn Param::with_default(self : Param, value : String) -> Param {
  { ..self, default_value: Some(value) }
}

///|
pub struct Function {
  name : String
  params : Array[Param]
  return_type : Type
  body : String? // Function body as raw code string for now
  doc : String?
  visibility : Visibility
  type_params : Array[String]
  is_async : Bool
  error_type : Type? // for `raise Error`
  receiver : (String, Type)? // (self_name, self_type) for methods
  source_ref : SourceRef?
}

///|
pub fn Function::new(name : String) -> Function {
  {
    name,
    params: [],
    return_type: Type::unit(),
    body: None,
    doc: None,
    visibility: Public,
    type_params: [],
    is_async: false,
    error_type: None,
    receiver: None,
    source_ref: None,
  }
}

///|
pub fn Function::with_param(self : Function, param : Param) -> Function {
  let params = self.params.copy()
  params.push(param)
  { ..self, params, }
}

///|
pub fn Function::with_params(
  self : Function,
  params : Array[Param],
) -> Function {
  let new_params = self.params.copy()
  for p in params {
    new_params.push(p)
  }
  { ..self, params: new_params }
}

///|
pub fn Function::with_return(self : Function, ty : Type) -> Function {
  { ..self, return_type: ty }
}

///|
pub fn Function::with_body(self : Function, body : String) -> Function {
  { ..self, body: Some(body) }
}

///|
pub fn Function::with_doc(self : Function, doc : String) -> Function {
  { ..self, doc: Some(doc) }
}

///|
pub fn Function::with_visibility(self : Function, vis : Visibility) -> Function {
  { ..self, visibility: vis }
}

///|
pub fn Function::with_type_params(
  self : Function,
  params : Array[String],
) -> Function {
  { ..self, type_params: params }
}

///|
pub fn Function::as_async(self : Function) -> Function {
  { ..self, is_async: true }
}

///|
pub fn Function::with_error(self : Function, error_type : Type) -> Function {
  { ..self, error_type: Some(error_type) }
}

///|
pub fn Function::with_receiver(
  self : Function,
  name : String,
  ty : Type,
) -> Function {
  { ..self, receiver: Some((name, ty)) }
}

///|
pub fn Function::with_source_ref(
  self : Function,
  source : SourceRef,
) -> Function {
  { ..self, source_ref: Some(source) }
}
