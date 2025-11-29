//
//  Created by Anton Spivak
//

// MARK: - BOC.Data

extension BOC {
    @usableFromInline
    struct Data {
        // MARK: Lifecycle

        /// Creates a new `BOC.Data` container with specified options, header flags, and root cells.
        ///
        /// - Parameters:
        ///  - includedOptions: Flags like `.indices` or `.crc32c`.
        ///  - headerFlags: Typically `(false, false)`.
        ///  - rootCells: The array of root `Cell`s in this BOC.
        init(includedOptions: IncludedOptions, headerFlags: (Bool, Bool), rootCells: [Cell]) {
            self.includedOptions = includedOptions
            self.headerFlags = headerFlags
            self.rootCells = rootCells
        }

        // MARK: Internal

        /// BOC options specifying whether indices or CRC32 are included, etc.
        @usableFromInline
        let includedOptions: IncludedOptions

        /// A tuple of flags extracted from the BOC header.
        @usableFromInline
        let headerFlags: (Bool, Bool)

        /// The root cell objects forming the top-level structure of the BOC.
        @usableFromInline
        let rootCells: [Cell]
    }
}

// MARK: - BOC.Data + Sendable

extension BOC.Data: Sendable {}

// MARK: - BOC.Data + Equatable

extension BOC.Data: Equatable {
    /// Two `BOC.Data` instances are equal if they have identical
    /// `includedOptions`, `headerFlags`, and `rootCells`.
    @usableFromInline
    static func == (lhs: BOC.Data, rhs: BOC.Data) -> Bool {
        lhs.includedOptions == rhs.includedOptions &&
            lhs.headerFlags == rhs.headerFlags &&
            lhs.rootCells == rhs.rootCells
    }
}

// MARK: - BOC.Data + Hashable

extension BOC.Data: Hashable {
    /// Combines `includedOptions`, each `headerFlags`, and `rootCells`
    /// into the hasher.
    @usableFromInline
    func hash(into hasher: inout Hasher) {
        hasher.combine(includedOptions)
        hasher.combine(headerFlags.0)
        hasher.combine(headerFlags.1)
        hasher.combine(rootCells)
    }
}
