///|
/// mizchi/codegen - Generic code generation library
///
/// This library provides an abstract IR (Intermediate Representation)
/// for code generation, with emitters for multiple targets:
/// - MoonBit source code
/// - JSON Schema
/// - Protocol Buffers (planned)
/// - FlatBuffers (planned)

// Re-export core types
pub type Type = @ir.Type

///|
pub type Struct = @ir.Struct

///|
pub type Enum = @ir.Enum

///|
pub type Field = @ir.Field

///|
pub type Function = @ir.Function

///|
pub type Module = @ir.Module

///|
pub type Visibility = @ir.Visibility

// Re-export builders
pub type StructBuilder = @builder.StructBuilder

///|
pub type EnumBuilder = @builder.EnumBuilder

///|
pub type FunctionBuilder = @builder.FunctionBuilder

///|
pub type ModuleBuilder = @builder.ModuleBuilder

// Re-export emitters
pub type MoonBitEmitter = @emit.MoonBitEmitter
