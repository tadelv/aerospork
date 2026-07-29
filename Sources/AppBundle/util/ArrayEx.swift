import Common

extension Array where Self.Element: Equatable {
    @discardableResult
    mutating func remove(element: Self.Element) -> Int? {
        if let index = firstIndex(of: element) {
            remove(at: index)
            return index
        } else {
            return nil
        }
    }
}

func - <T>(lhs: [T], rhs: [T]) -> [T] where T: Hashable {
    let r = rhs.toSet()
    return lhs.filter { !r.contains($0) }
}
