// Sources/protoc-gen-swift/MessageFieldGenerator.swift - Facts about a single message field
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// This code mostly handles the complex mapping between proto types and
/// the types provided by the Swift Protobuf Runtime.
///
// -----------------------------------------------------------------------------
import Foundation
import PluginLibrary
import SwiftProtobuf


extension Google_Protobuf_FieldDescriptorProto {

    var isRepeated: Bool {return label == .repeated}
    var isMessage: Bool {return type == .message}
    var isEnum: Bool {return type == .enum}
    var isGroup: Bool {return type == .group}

    var isPackable: Bool {
        switch type {
        case .string,.bytes,.group,.message:
            return false
        default:
            return label == .repeated
        }
    }

    var bareTypeName: String {
        if typeName.hasPrefix(".") {
            var t = ""
            for c in typeName.characters {
                if c == "." {
                    t = ""
                } else {
                    t.append(c)
                }
            }
            return t
        } else {
            return typeName
        }
    }

    func getIsMap(context: Context) -> Bool {
        if type != .message {return false}
        let m = context.getMessageForPath(path: typeName)!
        return m.options.mapEntry
    }


    func getProtoTypeName(context: Context) -> String {
        switch type {
        case .double: return "Double"
        case .float: return "Float"
        case .int64: return "Int64"
        case .uint64: return "UInt64"
        case .int32: return "Int32"
        case .fixed64: return "Fixed64"
        case .fixed32: return "Fixed32"
        case .bool: return "Bool"
        case .string: return "String"
        case .group: return context.getMessageNameForPath(path: typeName)!
        case .message: return context.getMessageNameForPath(path: typeName)!
        case .bytes: return "Bytes"
        case .uint32: return "UInt32"
        case .enum: return "Enum"
        case .sfixed32: return "SFixed32"
        case .sfixed64: return "SFixed64"
        case .sint32: return "SInt32"
        case .sint64: return "SInt64"
        }
    }

    func getSwiftBaseType(context: Context) -> String {
        switch type {
        case .double: return "Double"
        case .float: return "Float"
        case .int64: return "Int64"
        case .uint64: return "UInt64"
        case .int32: return "Int32"
        case .fixed64: return "UInt64"
        case .fixed32: return "UInt32"
        case .bool: return "Bool"
        case .string: return "String"
        case .group: return context.getMessageNameForPath(path: typeName)!
        case .message: return context.getMessageNameForPath(path: typeName)!
        case .bytes: return "Data"
        case .uint32: return "UInt32"
        case .enum: return context.getEnumNameForPath(path: typeName)!
        case .sfixed32: return "Int32"
        case .sfixed64: return "Int64"
        case .sint32: return "Int32"
        case .sint64: return "Int64"
        }
    }

    func getSwiftApiType(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName)!
            let keyField = m.field[0]
            let keyType = keyField.getSwiftBaseType(context: context)
            let valueField = m.field[1]
            let valueType = valueField.getSwiftBaseType(context: context)
            return "Dictionary<" + keyType + "," + valueType + ">"
        }
        switch label {
        case .repeated: return "[" + getSwiftBaseType(context: context) + "]"
        case .required, .optional:
            return getSwiftBaseType(context: context)
        }
    }

    func getSwiftStorageType(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName)!
            let keyField = m.field[0]
            let keyType = keyField.getSwiftBaseType(context: context)
            let valueField = m.field[1]
            let valueType = valueField.getSwiftBaseType(context: context)
            return "Dictionary<" + keyType + "," + valueType + ">"
        } else if isRepeated {
            return "[" + getSwiftBaseType(context: context) + "]"
        } else if isMessage || isGroup {
            return getSwiftBaseType(context: context) + "?"
        } else if isProto3 {
            return getSwiftBaseType(context: context)
        } else {
            return getSwiftBaseType(context: context) + "?"
        }
    }

    func getSwiftStorageDefaultValue(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {
            return "[:]"
        } else if isRepeated {
            return "[]"
        } else if isMessage || isGroup || !isProto3 {
            return "nil"
        } else {
            return getSwiftDefaultValue(context: context, isProto3: isProto3)
        }
    }

    func getSwiftDefaultValue(context: Context, isProto3: Bool) -> String {
        if getIsMap(context: context) {return "[:]"}
        if isRepeated {return "[]"}
        if let d = getSwiftProto2DefaultValue(context: context) {
            return d
        }
        switch type {
        case .bool: return "false"
        case .string: return "String()"
        case .bytes: return "SwiftProtobuf.Internal.emptyData"
        case .group, .message:
            return context.getMessageNameForPath(path: typeName)! + "()"
        case .enum:
            let e = context.enumDescriptor(forProtoName: typeName).proto
            if e.value.isEmpty {
                return "nil"
            } else {
                let defaultCase = e.value[0].name
                return context.getSwiftNameForEnumCase(path: typeName, caseName: defaultCase)
            }
        default: return "0"
        }
    }

    func getTraitsType(context: Context) -> String {
        if getIsMap(context: context) {
            let m = context.getMessageForPath(path: typeName)!
            let keyField = m.field[0]
            let keyTraits = keyField.getTraitsType(context: context)
            let valueField = m.field[1]
            let valueTraits = valueField.getTraitsType(context: context)
            if valueField.isMessage {
                return "SwiftProtobuf._ProtobufMessageMap<" + keyTraits + "," + valueTraits + ">"
            } else if valueField.isEnum {
                return "SwiftProtobuf._ProtobufEnumMap<" + keyTraits + "," + valueTraits + ">"
            } else {
                return "SwiftProtobuf._ProtobufMap<" + keyTraits + "," + valueTraits + ">"
            }
        }
        switch type {
        case .double: return "SwiftProtobuf.ProtobufDouble"
        case .float: return "SwiftProtobuf.ProtobufFloat"
        case .int64: return "SwiftProtobuf.ProtobufInt64"
        case .uint64: return "SwiftProtobuf.ProtobufUInt64"
        case .int32: return "SwiftProtobuf.ProtobufInt32"
        case .fixed64: return "SwiftProtobuf.ProtobufFixed64"
        case .fixed32: return "SwiftProtobuf.ProtobufFixed32"
        case .bool: return "SwiftProtobuf.ProtobufBool"
        case .string: return "SwiftProtobuf.ProtobufString"
        case .group: return getSwiftBaseType(context: context)
        case .message: return getSwiftBaseType(context: context)
        case .bytes: return "SwiftProtobuf.ProtobufBytes"
        case .uint32: return "SwiftProtobuf.ProtobufUInt32"
        case .enum: return getSwiftBaseType(context: context)
        case .sfixed32: return "SwiftProtobuf.ProtobufSFixed32"
        case .sfixed64: return "SwiftProtobuf.ProtobufSFixed64"
        case .sint32: return "SwiftProtobuf.ProtobufSInt32"
        case .sint64: return "SwiftProtobuf.ProtobufSInt64"
        }
    }

    func getSwiftProto2DefaultValue(context: Context) -> String? {
        guard hasDefaultValue else {return nil}
        switch type {
        case .double:
           switch defaultValue {
           case "inf": return "Double.infinity"
           case "-inf": return "-Double.infinity"
           case "nan": return "Double.nan"
           default: return defaultValue
           }
        case .float:
           switch defaultValue {
           case "inf": return "Float.infinity"
           case "-inf": return "-Float.infinity"
           case "nan": return "Float.nan"
           default: return defaultValue
           }
        case .bool: return defaultValue
        case .string:
          if defaultValue.isEmpty {
            // proto file listed the default as "", just pretend it wasn't set since
            // this is the default.
            return nil
          } else {
            return stringToEscapedStringLiteral(defaultValue)
          }
        case .bytes:
          if defaultValue.isEmpty {
            // proto file listed the default as "", just pretend it wasn't set since
            // this is the default.
            return nil
          } else {
            return escapedToDataLiteral(defaultValue)
          }
        case .enum:
            return context.getSwiftNameForEnumCase(path: typeName, caseName: defaultValue)
        default: return defaultValue
        }
    }
}

class MessageFieldGenerator: FieldGeneratorBase, FieldGenerator {
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let usesHeapStorage: Bool

    var descriptor: Google_Protobuf_FieldDescriptorProto { return fieldDescriptor.proto }
    let hasFieldPresence: Bool
    let swiftName: String
    let swiftHasName: String
    let swiftClearName: String
    let swiftStorageName: String
    var protoName: String {return descriptor.name}
    let comments: String
    let isProto3: Bool
    let context: Context

    var label: Google_Protobuf_FieldDescriptorProto.Label { return fieldDescriptor.label }

    var messageType: Descriptor { return fieldDescriptor.messageType }
    var enumType: EnumDescriptor { return fieldDescriptor.enumType }

    init(descriptor: FieldDescriptor,
         generatorOptions: GeneratorOptions,
         namer: SwiftProtobufNamer,
         context: Context,
         usesHeapStorage: Bool)
    {
        precondition(descriptor.oneofIndex == nil)

        self.generatorOptions = generatorOptions
        self.namer = namer
        self.usesHeapStorage = usesHeapStorage

        hasFieldPresence = descriptor.hasFieldPresence
        let names = namer.messagePropertyNames(field: descriptor, includeHasAndClear: descriptor.hasFieldPresence)
        swiftName = names.value
        swiftHasName = names.has
        swiftClearName = names.clear
        self.swiftStorageName = "_" + self.swiftName
        self.comments = descriptor.protoSourceComments()
        self.isProto3 = descriptor.file.syntax == .proto3
        self.context = context

        super.init(descriptor: descriptor)
    }

    // Note: this could still be a map (since those are repeated message fields
    var isGroupOrMessage: Bool {
        switch fieldDescriptor.type {
        case .group, .message:
            return true
        default:
            return false
        }
    }

    var isGroup: Bool {return descriptor.isGroup}
    var isMap: Bool {return fieldDescriptor.isMap}
    var isMessage: Bool {return descriptor.isMessage}
    var isEnum: Bool {return descriptor.type == .enum}
    var isString: Bool {return descriptor.type == .string}
    var isBytes: Bool {return descriptor.type == .bytes}
    var isPacked: Bool {return descriptor.isPackable &&
        (descriptor.options.hasPacked ? descriptor.options.packed : isProto3)}
    var isRepeated: Bool {return fieldDescriptor.label == .repeated}

    var name: String {return descriptor.name}
    var protoTypeName: String {return descriptor.getProtoTypeName(context: context)}
    var swiftBaseType: String {return descriptor.getSwiftBaseType(context: context)}
    var swiftApiType: String {return descriptor.getSwiftApiType(context: context, isProto3: isProto3)}

    var swiftDefaultValue: String {
        return descriptor.getSwiftDefaultValue(context: context, isProto3: isProto3)
    }

    var swiftProto2DefaultValue: String? {
        return descriptor.getSwiftProto2DefaultValue(context: context)
    }

    var swiftStorageType: String {
        return descriptor.getSwiftStorageType(context: context, isProto3: isProto3)
    }

    var swiftStorageDefaultValue: String {
        return descriptor.getSwiftStorageDefaultValue(context: context, isProto3: isProto3)
    }

    var traitsType: String {return descriptor.getTraitsType(context: context)}

    func generateStorage(printer p: inout CodePrinter) {
        if usesHeapStorage {
            p.print("var \(swiftStorageName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
        } else {
          // If this field has field presence, the there is a private storage variable.
          if hasFieldPresence {
            p.print("fileprivate var \(swiftStorageName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
          }
        }
    }

    func generateInterface(printer p: inout CodePrinter) {
        if usesHeapStorage {
            generateProxyIvar(printer: &p)
        } else {
            generateTopIvar(printer: &p)
        }

        guard hasFieldPresence else { return }

        let storagePrefix = usesHeapStorage ? "_storage." : "self."
        p.print(
            "/// Returns true if `\(swiftName)` has been explicitly set.\n",
            "\(generatorOptions.visibilitySourceSnippet)var \(swiftHasName): Bool {return \(storagePrefix)\(swiftStorageName) != nil}\n")

        p.print(
            "/// Clears the value of `\(swiftName)`. Subsequent reads from it will return its default value.\n",
            "\(generatorOptions.visibilitySourceSnippet)mutating func \(swiftClearName)() {\(storagePrefix)\(swiftStorageName) = nil}\n")
    }

    func generateStorageClassClone(printer p: inout CodePrinter) {
        p.print("\(swiftStorageName) = source.\(swiftStorageName)\n")
    }

    func generateFieldComparison(printer p: inout CodePrinter) {
        p.print("if \(storedProperty()) != \(storedProperty(in: "other")) {return false}\n")
    }

   func generateRequiredFieldCheck(printer p: inout CodePrinter) {
       guard label == .required else { return }
       p.print("if \(storedProperty()) == nil {return false}\n")
    }

    func generateIsInitializedCheck(printer p: inout CodePrinter) {
        guard isGroupOrMessage && messageType.hasRequiredFields() else { return }

        if isRepeated {  // Map or Array
            p.print("if !SwiftProtobuf.Internal.areAllInitialized(\(storedProperty())) {return false}\n")
        } else {
            p.print("if let v = \(storedProperty()), !v.isInitialized {return false}\n")
        }
    }

    private func generateTopIvar(printer p: inout CodePrinter) {
        p.print("\n", comments)
        if !isRepeated && !isMap && !isProto3 {
            p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftApiType) {\n")
            p.indent()
            p.print(
                "get {return \(swiftStorageName) ?? \(swiftDefaultValue)}\n",
                "set {\(swiftStorageName) = newValue}\n")
            p.outdent()
            p.print("}\n")
        } else {
            p.print("\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftStorageType) = \(swiftStorageDefaultValue)\n")
        }
    }

    private func generateProxyIvar(printer p: inout CodePrinter) {
        p.print(
            "\n",
            comments,
            "\(generatorOptions.visibilitySourceSnippet)var \(swiftName): \(swiftApiType) {\n")
        p.indent()

        let defaultClause: String
        if isMap || isRepeated {
            defaultClause = ""
        } else if isMessage || isGroup {
            defaultClause = " ?? " + swiftDefaultValue
        } else if let d = swiftProto2DefaultValue {
            defaultClause = " ?? " + d
        } else {
            defaultClause = isProto3 ? "" : " ?? " + swiftDefaultValue
        }
        p.print(
            "get {return _storage.\(swiftStorageName)\(defaultClause)}\n",
            "set {_uniqueStorage().\(swiftStorageName) = newValue}\n")

        p.outdent()
        p.print("}\n")
    }

    func generateDecodeFieldCase(printer p: inout CodePrinter) {
        let prefix: String
        if usesHeapStorage {
            prefix = "_storage._"
        } else if !isRepeated && !isMap && !isProto3 {
            prefix = "self._"
        } else {
            prefix = "self."
        }

        let decoderMethod: String
        let traitsArg: String
        let valueArg: String
        if isMap {
            // Map fields
            decoderMethod = "decodeMapField"
            traitsArg = "fieldType: \(traitsType).self"
            valueArg = "value: &\(prefix)\(swiftName)"
        } else if isGroup || isMessage || isEnum {
            // Message, Group, Enum fields
            let modifier = (isRepeated ? "Repeated" : "Singular")
            let special = isGroup ? "Group"
                         : isMessage ? "Message"
                         : isEnum ? "Enum"
                         : ""
            decoderMethod = "decode\(modifier)\(special)Field"
            traitsArg = ""
            valueArg = "value: &\(prefix)\(swiftName)"
        } else {
            // Primitive fields
            let modifier = (isRepeated ? "Repeated" : "Singular")
            let protoType = descriptor.getProtoTypeName(context: context)
            decoderMethod = "decode\(modifier)\(protoType)Field"
            traitsArg = ""
            valueArg = "value: &\(prefix)\(swiftName)"
        }
        let separator = traitsArg.isEmpty ? "" : ", "
        p.print("case \(number): try decoder.\(decoderMethod)(\(traitsArg)\(separator)\(valueArg))\n")
    }

    func generateTraverse(printer p: inout CodePrinter) {
        let prefix: String
        if usesHeapStorage {
            prefix = "_storage._"
        } else if !isRepeated && !isMap && !isProto3 {
            prefix = "self._"
        } else {
            prefix = "self."
        }

        let visitMethod: String
        let fieldTypeArg: String
        if isMap {
            visitMethod = "visitMapField"
            fieldTypeArg = "fieldType: \(traitsType).self, "
        } else if isGroup || isMessage || isEnum {
            let modifier = (isPacked ? "Packed"
                         : isRepeated ? "Repeated"
                         : "Singular")
            let special = isGroup ? "Group"
                         : isMessage ? "Message"
                         : isEnum ? "Enum"
                         : ""
            visitMethod = "visit\(modifier)\(special)Field"
            fieldTypeArg = ""
        } else if !isRepeated && descriptor.type == .int64 {
            visitMethod = "visitSingularInt64Field"
            fieldTypeArg = ""
        } else {
            let modifier = (isPacked ? "Packed"
                         : isRepeated ? "Repeated"
                                      : "Singular")
            let protoType = descriptor.getProtoTypeName(context: context)
            visitMethod = "visit\(modifier)\(protoType)Field"
            fieldTypeArg = ""
        }


        let varName: String
        let conditional: String
        if isRepeated {
            varName = prefix + swiftName
            conditional = "!\(varName).isEmpty"
        } else if isGroup || isMessage || !isProto3 {
            varName = "v"
            conditional = "let v = \(prefix)\(swiftName)"
        } else {
            assert(isProto3)
            varName = prefix + swiftName
            if isString || isBytes {
                conditional = ("!\(varName).isEmpty")
            } else {
                conditional = ("\(varName) != \(swiftDefaultValue)")
            }
        }

        p.print("if \(conditional) {\n")
        p.indent()
        p.print("try visitor.\(visitMethod)(\(fieldTypeArg)value: \(varName), fieldNumber: \(number))\n")
        p.outdent()
        p.print("}\n")
    }

    private func storedProperty(in variable: String = "") -> String {
      if usesHeapStorage {
        return "\(variable)_storage.\(swiftStorageName)"
      }
      let prefix = variable.isEmpty ? "self." : "\(variable)."
      if isRepeated || isMap {
        return "\(prefix)\(swiftName)"
      }
      if !isProto3 {
        return "\(prefix)\(swiftStorageName)"
      }
      return "\(prefix)\(swiftName)"
    }
}
