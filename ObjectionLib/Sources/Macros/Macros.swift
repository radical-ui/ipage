import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct StructMember {
    let name: String;
    let type: String
    let isOptional: Bool
    
    func getFromAnyDef() -> String {
        return "\(name): try \(type).fromAny(any: anyObject[\"\(name)\"])"
    }
    
    func getToAnyDef() -> String {
        return "\"\(name)\": self.\(name).toAny()"
    }
    
    func getSchemaDef() -> String {
        return "[ \"name\": \"\(name)\", \"type\": \(type).getSchema(), \"isOptional\": \(isOptional ? "true" : "false") ]"
    }
}

public struct SchemaMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        var members: [StructMember] = []
        
        for item in declaration.memberBlock.members {
            let decl = item.decl
            
            guard case .variableDecl(let variable) = decl.as(DeclSyntaxEnum.self) else {
                continue
            }
            
            for binding in variable.bindings {
                guard case .identifierPattern(let pattern) = binding.pattern.as(PatternSyntaxEnum.self) else {
                    continue
                }
                
                let name = pattern.identifier.text
                guard let typeSyntax = binding.typeAnnotation?.type else { continue }
                guard let (isOptional, type) = getTypeName(syntax: typeSyntax) else { continue }
                
                members.append(StructMember(name: name, type: type, isOptional: isOptional))
            }
        }
        
        return [
            try ExtensionDeclSyntax("""
                extension \(type.trimmed): Schema {
                    public static func fromAny(any: Any) throws -> Object {
                        guard let anyObject = any as? [String: Any] else {
                            throw DeserializationError(expected: "object", got: String(describing: any))
                        }
                        
                        return Object(
                            \(raw: members.map({ member in member.getFromAnyDef() }).joined(separator: ","))
                        )
                    }
                    
                    public func toAny() -> Any {
                        [
                            \(raw: members.map({ member in member.getToAnyDef() }).joined(separator: ","))
                        ]
                    }
                    
                    public static func getSchema() -> Any {
                        return [
                            "$": "struct",
                            "properties": [
                                \(raw: members.map({ member in member.getSchemaDef() }).joined(separator: ","))
                            ]
                        ]
                    }
                }
            """)
        ]
    }
}

func getTypeName(syntax: TypeSyntax) -> (Bool, String)? {
    switch (syntax.as(TypeSyntaxEnum.self)) {
    case .identifierType(let inner):
        return (false, inner.name.text)
    case .optionalType(let inner):
        if let type = getTypeName(syntax: inner.wrappedType) {
            return (true, type.1)
        } else {
            return nil
        }
    default:
        return nil
    }
}

@main
struct ObjectionLibPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SchemaMacro.self,
    ]
}
