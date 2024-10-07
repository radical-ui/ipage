import Object
import Foundation

let json = try JSONSerialization.data(withJSONObject: [
    "object": Object.getSchema(),
    "initial_objects": []
])

let text = String(data: json, encoding: .utf8)!

var to = "\(FileManager.default.currentDirectoryPath)/schema.json"
try json.write(to: URL(fileURLWithPath: to))

print("Write schema to \(to)")
