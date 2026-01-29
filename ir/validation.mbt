///|
/// Validation constraints for fields

///|
pub struct Constraints {
  required : Bool           // NOT NULL / required
  min_length : Int?         // minimum string length
  max_length : Int?         // maximum string length (VARCHAR(n))
  min_value : Int64?        // minimum numeric value
  max_value : Int64?        // maximum numeric value
  pattern : String?         // regex pattern
  unsigned : Bool           // non-negative constraint
  custom : Array[String]    // custom validation expressions
}

///|
pub fn Constraints::new() -> Constraints {
  {
    required: false,
    min_length: None,
    max_length: None,
    min_value: None,
    max_value: None,
    pattern: None,
    unsigned: false,
    custom: [],
  }
}

///|
pub fn Constraints::as_required(self : Constraints) -> Constraints {
  { ..self, required: true }
}

///|
pub fn Constraints::with_min_length(self : Constraints, len : Int) -> Constraints {
  { ..self, min_length: Some(len) }
}

///|
pub fn Constraints::with_max_length(self : Constraints, len : Int) -> Constraints {
  { ..self, max_length: Some(len) }
}

///|
pub fn Constraints::with_min_value(self : Constraints, val : Int64) -> Constraints {
  { ..self, min_value: Some(val) }
}

///|
pub fn Constraints::with_max_value(self : Constraints, val : Int64) -> Constraints {
  { ..self, max_value: Some(val) }
}

///|
pub fn Constraints::with_pattern(self : Constraints, pat : String) -> Constraints {
  { ..self, pattern: Some(pat) }
}

///|
pub fn Constraints::as_unsigned(self : Constraints) -> Constraints {
  { ..self, unsigned: true }
}

///|
pub fn Constraints::with_custom(self : Constraints, expr : String) -> Constraints {
  let custom = self.custom.copy()
  custom.push(expr)
  { ..self, custom }
}

///|
pub fn Constraints::is_empty(self : Constraints) -> Bool {
  not(self.required) &&
  (self.min_length is None) &&
  (self.max_length is None) &&
  (self.min_value is None) &&
  (self.max_value is None) &&
  (self.pattern is None) &&
  not(self.unsigned) &&
  self.custom.length() == 0
}
