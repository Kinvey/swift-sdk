import ObjectMapper

internal final class AnyMapper {
  private let _mapJSON: ([String: Any]) -> Any?

  init<T: BaseMappable>(_ mapper: Mapper<T>) {
    _mapJSON = { mapper.map(JSON: $0) }
  }

  func map(JSON: [String: Any]) -> Any? {
    return _mapJSON(JSON)
  }
}
