import Testing
@testable import Services

@Suite("Services Tests")
struct ServicesTests {
    @Test("Services version is correct")
    func servicesVersion() {
        #expect(Services.version == "1.0.0")
    }
}
