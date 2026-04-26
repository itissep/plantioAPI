enum CareEventKind {
    static let allValues = ["watering", "fertilizing", "repotting", "note"]

    static func isValid(_ kind: String) -> Bool {
        allValues.contains(kind.lowercased())
    }
}
