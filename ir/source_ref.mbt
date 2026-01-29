///|
/// Source reference information for traceability

///|
/// Represents the source location/reference for generated code
pub struct SourceRef {
  /// Schema or source identifier (e.g., "UserSchema", "openapi.yaml#/components/schemas/User")
  id : String
  /// Optional file path
  file : String?
  /// Optional line number
  line : Int?
  /// Optional additional context
  context : String?
}

///|
pub fn SourceRef::new(id : String) -> SourceRef {
  { id, file: None, line: None, context: None }
}

///|
pub fn SourceRef::with_file(self : SourceRef, file : String) -> SourceRef {
  { ..self, file: Some(file) }
}

///|
pub fn SourceRef::with_line(self : SourceRef, line : Int) -> SourceRef {
  { ..self, line: Some(line) }
}

///|
pub fn SourceRef::with_context(self : SourceRef, ctx : String) -> SourceRef {
  { ..self, context: Some(ctx) }
}

///|
/// Format the source reference as a comment string
pub fn SourceRef::to_comment(self : SourceRef) -> String {
  let buf = StringBuilder::new()
  buf.write_string("Source: ")
  buf.write_string(self.id)
  match self.file {
    Some(f) => {
      buf.write_string(" (")
      buf.write_string(f)
      match self.line {
        Some(l) => {
          buf.write_string(":")
          buf.write_string(l.to_string())
        }
        None => ()
      }
      buf.write_string(")")
    }
    None => ()
  }
  match self.context {
    Some(ctx) => {
      buf.write_string(" - ")
      buf.write_string(ctx)
    }
    None => ()
  }
  buf.to_string()
}
