//
//  Created by Anton Spivak
//

import FundamentalsExtensions

// MARK: - DeviceInformation

public struct DeviceInformation {
    // MARK: Lifecycle

    init(
        platform: HostApplication.Platform,
        appName: String,
        appVersion: String,
        maxProtocolVersion: Int,
        features: [HostApplication.Feature]
    ) {
        self.platform = platform
        self.appName = appName
        self.appVersion = appVersion
        self.maxProtocolVersion = maxProtocolVersion
        self.features = features
    }

    // MARK: Public

    public let platform: HostApplication.Platform
    public let appName: String
    public let appVersion: String
    public let maxProtocolVersion: Int
    public let features: [HostApplication.Feature]
}

// MARK: Codable

extension DeviceInformation: Codable {}

// MARK: Sendable

extension DeviceInformation: Sendable {}

// MARK: DeviceInformation.Platform

extension DeviceInformation {
    init(from hostApplication: HostApplication) {
        self.init(
            platform: hostApplication.platform,
            appName: hostApplication.name,
            appVersion: hostApplication.version,
            maxProtocolVersion: 2,
            features: hostApplication.features
        )
    }
}
