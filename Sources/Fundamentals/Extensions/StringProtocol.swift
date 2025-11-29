//
//  Created by Anton Spivak
//

public extension StringProtocol {
    subscript(index: Int) -> SubSequence {
        return self[index ..< index + 1]
    }

    func substring(fromIndex: Int) -> SubSequence {
        return self[Swift.min(fromIndex, count) ..< count]
    }

    func substring(toIndex: Int) -> SubSequence {
        return self[0 ..< Swift.max(0, toIndex)]
    }

    subscript(range: Range<Int>) -> SubSequence {
        let range = Range(uncheckedBounds: (
            lower: Swift.max(0, Swift.min(count, range.lowerBound)),
            upper: Swift.min(count, Swift.max(0, range.upperBound))
        ))

        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)

        return self[start ..< end]
    }
}
