///|
/// Core type representation in the IR

///|
pub enum Type {
  /// Primitive types: "Int", "Int64", "String", "Bool", "Double", "Bytes", "Unit"
  Primitive(String)
  /// Optional type: Option[T]
  Optional(Type)
  /// Array type: Array[T]
  Array(Type)
  /// Map type: Map[K, V]
  Map(Type, Type)
  /// Named type with optional type arguments: MyStruct[T, U]
  Named(String, Array[Type])
  /// Function type: (A, B) -> C
  Function(Array[Type], Type)
  /// Tuple type: (A, B, C)
  Tuple(Array[Type])
  /// Error type for raise: fn() -> T raise E
  Error(Type)
}

///|
impl Show for Type with output(self, logger) {
  match self {
    Primitive(name) => logger.write_string(name)
    Optional(inner) => {
      inner.output(logger)
      logger.write_string("?")
    }
    Array(inner) => {
      logger.write_string("Array[")
      inner.output(logger)
      logger.write_string("]")
    }
    Map(key, value) => {
      logger.write_string("Map[")
      key.output(logger)
      logger.write_string(", ")
      value.output(logger)
      logger.write_string("]")
    }
    Named(name, args) =>
      if args.is_empty() {
        logger.write_string(name)
      } else {
        logger.write_string(name)
        logger.write_string("[")
        for i, arg in args {
          if i > 0 {
            logger.write_string(", ")
          }
          arg.output(logger)
        }
        logger.write_string("]")
      }
    Function(params, ret) => {
      logger.write_string("(")
      for i, param in params {
        if i > 0 {
          logger.write_string(", ")
        }
        param.output(logger)
      }
      logger.write_string(") -> ")
      ret.output(logger)
    }
    Tuple(types) => {
      logger.write_string("(")
      for i, ty in types {
        if i > 0 {
          logger.write_string(", ")
        }
        ty.output(logger)
      }
      logger.write_string(")")
    }
    Error(inner) => {
      logger.write_string("Error[")
      inner.output(logger)
      logger.write_string("]")
    }
  }
}

// Convenience constructors
///|
pub fn Type::unit() -> Type {
  Primitive("Unit")
}

///|
pub fn Type::bool() -> Type {
  Primitive("Bool")
}

///|
pub fn Type::int() -> Type {
  Primitive("Int")
}

///|
pub fn Type::int64() -> Type {
  Primitive("Int64")
}

///|
pub fn Type::uint() -> Type {
  Primitive("UInt")
}

///|
pub fn Type::uint64() -> Type {
  Primitive("UInt64")
}

///|
pub fn Type::double() -> Type {
  Primitive("Double")
}

///|
pub fn Type::string() -> Type {
  Primitive("String")
}

///|
pub fn Type::bytes() -> Type {
  Primitive("Bytes")
}

///|
pub fn Type::optional(inner : Type) -> Type {
  Optional(inner)
}

///|
pub fn Type::array(inner : Type) -> Type {
  Array(inner)
}

///|
pub fn Type::map(key : Type, value : Type) -> Type {
  Map(key, value)
}

///|
pub fn Type::named(name : String) -> Type {
  Named(name, [])
}

///|
pub fn Type::named_with(name : String, args : Array[Type]) -> Type {
  Named(name, args)
}

///|
pub fn Type::function(params : Array[Type], ret : Type) -> Type {
  Function(params, ret)
}

///|
pub fn Type::tuple(types : Array[Type]) -> Type {
  Tuple(types)
}

///|
pub fn Type::error(inner : Type) -> Type {
  Error(inner)
}
