///|
/// Naming convention utilities

///|
pub fn to_snake_case(s : String) -> String {
  let buf = StringBuilder::new()
  let chars = s.to_array()
  for i, c in chars {
    if c >= 'A' && c <= 'Z' {
      if i > 0 {
        let prev = chars[i - 1]
        // Add underscore if previous char is lowercase or
        // if next char exists and is lowercase (for acronyms like "XMLParser" -> "xml_parser")
        if prev >= 'a' && prev <= 'z' {
          buf.write_char('_')
        } else if i + 1 < chars.length() {
          let next = chars[i + 1]
          if next >= 'a' && next <= 'z' {
            buf.write_char('_')
          }
        }
      }
      buf.write_char(char_to_lower(c))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
pub fn to_pascal_case(s : String) -> String {
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  for c in s {
    if c == '_' || c == '-' || c == ' ' {
      capitalize_next = true
    } else if capitalize_next {
      buf.write_char(char_to_upper(c))
      capitalize_next = false
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
pub fn to_camel_case(s : String) -> String {
  let pascal = to_pascal_case(s)
  if pascal.length() == 0 {
    return ""
  }
  let chars = pascal.to_array()
  chars[0] = char_to_lower(chars[0])
  String::from_array(chars)
}

///|
fn char_to_lower(c : Char) -> Char {
  if c >= 'A' && c <= 'Z' {
    (c.to_int() + 32).unsafe_to_char()
  } else {
    c
  }
}

///|
fn char_to_upper(c : Char) -> Char {
  if c >= 'a' && c <= 'z' {
    (c.to_int() - 32).unsafe_to_char()
  } else {
    c
  }
}
