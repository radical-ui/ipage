@attached(extension, conformances: Schema, names: arbitrary)
public macro Schema() = #externalMacro(module: "Macros", type: "SchemaMacro")

public protocol Schema {
    static func fromAny(any: Any) throws -> Self
    func toAny() -> Any
    static func getSchema() -> Any
}

public struct DeserializationError: Error {
    let expected: String;
    let got: String;
    
    public init(expected: String, got: String) {
        self.expected = expected
        self.got = got
    }
}

extension String: Schema {
    public static func fromAny(any: Any) throws -> String {
        guard let string = any as? String else {
            throw DeserializationError(expected: "string", got: String(describing: any))
        }
        
        return string
    }
    
    public func toAny() -> Any {
        return self
    }
    
    public static func getSchema() -> Any {
        return [ "$": "string" ]
    }
}
