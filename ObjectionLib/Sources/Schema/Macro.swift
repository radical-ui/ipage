
@attached(member)
@attached(extension, conformances: Schema)
public macro Schema() = #externalMacro(module: "Macros", type: "SchemaMacro")

public protocol Schema {
    static func fromAny(any: Any) -> Self
    func toAny() -> Any
    func getSchema() -> Schema
}
