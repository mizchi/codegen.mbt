///|
/// String escaping utilities

///|
pub fn escape_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      '\\' => buf.write_string("\\\\")
      '"' => buf.write_string("\\\"")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
pub fn escape_multiline(s : String) -> String {
  // For MoonBit multiline strings with #| prefix
  let lines = split_lines(s)
  let buf = StringBuilder::new()
  for i, line in lines {
    if i > 0 {
      buf.write_char('\n')
    }
    buf.write_string("  #|")
    buf.write_string(line)
  }
  buf.to_string()
}

///|
fn split_lines(s : String) -> Array[String] {
  let lines : Array[String] = []
  let current = StringBuilder::new()
  for c in s {
    if c == '\n' {
      lines.push(current.to_string())
      current.reset()
    } else if c != '\r' {
      current.write_char(c)
    }
  }
  let last = current.to_string()
  if last.length() > 0 {
    lines.push(last)
  }
  lines
}

///|
pub fn indent(s : String, depth : Int) -> String {
  let prefix = String::make(depth * 2, ' ')
  let lines = split_lines(s)
  let buf = StringBuilder::new()
  for i, line in lines {
    if i > 0 {
      buf.write_char('\n')
    }
    if line.length() > 0 {
      buf.write_string(prefix)
      buf.write_string(line)
    }
  }
  buf.to_string()
}
