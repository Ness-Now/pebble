enum PebbleAgentVisualIdentity {
    static let variants = [
        "villager_farmer", "villager_fisherman", "villager_shepherd",
        "villager_toolsmith", "villager_mason", "villager",
    ]

    static func variant(
        for agentID: String,
        availableVariants: [String] = variants
    ) -> String? {
        guard !availableVariants.isEmpty else { return nil }
        let stable = agentID.utf8.reduce(UInt64(14_695_981_039_346_656_037)) {
            ($0 ^ UInt64($1)) &* 1_099_511_628_211
        }
        return availableVariants[Int(stable % UInt64(availableVariants.count))]
    }
}
