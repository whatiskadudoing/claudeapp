import Testing
@testable import Core

@Suite("Core Tests")
struct CoreTests {
    @Test("Core version is correct")
    func coreVersion() {
        #expect(Core.version == "1.0.0")
    }
}
