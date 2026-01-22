import Testing
@testable import Domain

@Suite("Domain Tests")
struct DomainTests {
    @Test("Domain version is correct")
    func domainVersion() {
        #expect(Domain.version == "1.0.0")
    }
}
