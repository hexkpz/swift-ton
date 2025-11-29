//
//  Created by Anton Spivak
//

// MARK: - HostApplicationEvent

struct HostApplicationEvent<T> where T: Codable, T: Sendable {
    // MARK: Lifecycle

    init(id: Int, name: String, payload: T) {
        self.id = id
        self.name = name
        self.payload = payload
    }

    // MARK: Internal

    let id: Int
    let name: String
    let payload: T
}

// MARK: Sendable

extension HostApplicationEvent: Sendable {}

// MARK: Codable

extension HostApplicationEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name = "event"
        case payload
    }
}
