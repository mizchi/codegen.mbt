///|
/// Fluent builder for Function

///|
pub struct FunctionBuilder {
  name : String
  params : Array[@ir.Param]
  mut return_type : @ir.Type
  mut body : String?
  mut doc : String?
  mut visibility : @ir.Visibility
  type_params : Array[String]
  mut is_async : Bool
  mut error_type : @ir.Type?
  mut receiver : (String, @ir.Type)?
}

///|
pub fn FunctionBuilder::new(name : String) -> FunctionBuilder {
  {
    name,
    params: [],
    return_type: @ir.Type::unit(),
    body: None,
    doc: None,
    visibility: @ir.Visibility::public(),
    type_params: [],
    is_async: false,
    error_type: None,
    receiver: None,
  }
}

///|
pub fn FunctionBuilder::with_doc(
  self : FunctionBuilder,
  doc : String
) -> FunctionBuilder {
  self.doc = Some(doc)
  self
}

///|
pub fn FunctionBuilder::with_visibility(
  self : FunctionBuilder,
  vis : @ir.Visibility
) -> FunctionBuilder {
  self.visibility = vis
  self
}

///|
pub fn FunctionBuilder::add_type_param(
  self : FunctionBuilder,
  name : String
) -> FunctionBuilder {
  self.type_params.push(name)
  self
}

///|
pub fn FunctionBuilder::add_param(
  self : FunctionBuilder,
  name : String,
  ty : @ir.Type
) -> FunctionBuilder {
  self.params.push(@ir.Param::new(name, ty))
  self
}

///|
pub fn FunctionBuilder::add_labeled_param(
  self : FunctionBuilder,
  name : String,
  ty : @ir.Type,
  label : String
) -> FunctionBuilder {
  self.params.push(@ir.Param::new(name, ty).with_label(label))
  self
}

///|
pub fn FunctionBuilder::add_optional_param(
  self : FunctionBuilder,
  name : String,
  ty : @ir.Type,
  default_val : String
) -> FunctionBuilder {
  self.params.push(@ir.Param::new(name, ty).with_default(default_val))
  self
}

///|
pub fn FunctionBuilder::add_param_with(
  self : FunctionBuilder,
  param : @ir.Param
) -> FunctionBuilder {
  self.params.push(param)
  self
}

///|
pub fn FunctionBuilder::with_return(
  self : FunctionBuilder,
  ty : @ir.Type
) -> FunctionBuilder {
  self.return_type = ty
  self
}

///|
pub fn FunctionBuilder::with_raises(
  self : FunctionBuilder,
  error_type : @ir.Type
) -> FunctionBuilder {
  self.error_type = Some(error_type)
  self
}

///|
pub fn FunctionBuilder::as_async(self : FunctionBuilder) -> FunctionBuilder {
  self.is_async = true
  self
}

///|
pub fn FunctionBuilder::with_body(
  self : FunctionBuilder,
  code : String
) -> FunctionBuilder {
  self.body = Some(code)
  self
}

///|
pub fn FunctionBuilder::with_receiver(
  self : FunctionBuilder,
  name : String,
  ty : @ir.Type
) -> FunctionBuilder {
  self.receiver = Some((name, ty))
  self
}

///|
pub fn FunctionBuilder::build(self : FunctionBuilder) -> @ir.Function {
  let f = @ir.Function::new(self.name)
    .with_params(self.params)
    .with_return(self.return_type)
    .with_visibility(self.visibility)
    .with_type_params(self.type_params)
  let f = if self.is_async { f.as_async() } else { f }
  let f = match self.error_type {
    Some(e) => f.with_error(e)
    None => f
  }
  let f = match self.receiver {
    Some((name, ty)) => f.with_receiver(name, ty)
    None => f
  }
  let f = match self.body {
    Some(b) => f.with_body(b)
    None => f
  }
  match self.doc {
    Some(d) => f.with_doc(d)
    None => f
  }
}
