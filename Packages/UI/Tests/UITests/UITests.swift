import Testing
@testable import UI

@Suite("UI Tests")
struct UITests {
    @Test("UI version is correct")
    func uiVersion() {
        #expect(UI.version == "1.0.0")
    }
}
