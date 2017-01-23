@testable import Kinvey
import ObjectMapper
import XCTest

final class AnyMapperTests: XCTestCase {
    func testErasesMappedType() {
        let originalUser = TestModel()
        originalUser.testProperty = "this is a test"

        let mapper = AnyMapper(Mapper<TestModel>())
        let newUser = mapper.map(JSON: originalUser.toJSON()) as? TestModel
        XCTAssertNotNil(newUser?.testProperty)
        XCTAssertEqual(newUser?.testProperty, "this is a test")
    }
}

private final class TestModel: Mappable {
    var testProperty: String?

    init() {
    }

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        testProperty <- map["testProperty"]
    }
}
