import SwiftUI

struct ConfigRequestBody: Codable {
    var systemid: String
    var password: String
    var request: String = "getconfig"
    
    init(systemID: String, password: String){
        self.systemid = systemID
        self.password = password
    }
}

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello")
        }
    }
}

