# codegen.mbt

Generic code generation library for MoonBit with abstract IR (Intermediate Representation).

## Features

- **Abstract IR**: Define types, structs, enums, functions once, emit to multiple targets
- **Multi-language emitters**: MoonBit, TypeScript, Rust, Protocol Buffers, JSON Schema, FlatBuffers, Zod
- **Fluent builders**: Easy-to-use builder pattern for constructing IR
- **Validation**: Generate validation code from JSON Schema

## Installation

```bash
moon add mizchi/codegen
```

## Usage

```moonbit
// Build a module using fluent API
let module = @builder.ModuleBuilder::new()
  .with_name("example")
  .add_struct(
    @builder.StructBuilder::new("User")
      .add_field("id", @ir.Type::int())
      .add_field("name", @ir.Type::string())
      .add_field("email", @ir.Type::optional(@ir.Type::string()))
      .build()
  )
  .add_enum(
    @builder.EnumBuilder::new("Status")
      .add_unit_variant("Active")
      .add_unit_variant("Inactive")
      .add_variant("Pending", [("reason", @ir.Type::string())])
      .build()
  )
  .build()

// Emit to MoonBit
let moonbit_code = @emit.MoonBitEmitter::new().emit_module(module)

// Emit to TypeScript
let ts_code = @emit.TypeScriptEmitter::new().emit_module(module)

// Emit to Rust
let rust_code = @emit.RustEmitter::new().emit_module(module)
```

## Supported Emitters

| Emitter | Output |
|---------|--------|
| `MoonBitEmitter` | MoonBit source code |
| `TypeScriptEmitter` | TypeScript interfaces and types |
| `RustEmitter` | Rust structs and enums |
| `ProtobufEmitter` | Protocol Buffers v3 schema |
| `JsonSchemaEmitter` | JSON Schema |
| `FlatBuffersEmitter` | FlatBuffers schema |
| `ZodEmitter` | Zod validation schemas |

## IR Types

```moonbit
pub enum Type {
  Primitive(String)      // "Int", "String", "Bool", etc.
  Optional(Type)         // Option[T]
  Array(Type)            // Array[T]
  Map(Type, Type)        // Map[K, V]
  Named(String, Array[Type]) // Custom types with generics
  Function(Array[Type], Type) // (A, B) -> C
  Tuple(Array[Type])     // (A, B, C)
  Error(Type)            // Error type for raise
}
```

## Packages

- `@ir` - Core IR types (Type, Struct, Enum, Function, Module, etc.)
- `@builder` - Fluent builders (ModuleBuilder, StructBuilder, EnumBuilder, FunctionBuilder)
- `@emit` - Code emitters for various target languages
- `@utils` - Utility functions (naming conventions, escaping)

## License

MIT
