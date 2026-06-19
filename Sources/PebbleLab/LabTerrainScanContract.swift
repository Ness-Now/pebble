struct LabTerrainScanScenarioContract {
    let scenario: String
    let agentX: Int
    let agentZ: Int
    let radius: Int
    let relation: String
    let order: String
    let expectedCellsPlanned: Int
    let expectedCellsObserved: Int
    let expectedUniqueChunks: Int?
    let requiresChunkBoundaryCrossing: Bool
}

func terrainScanScenarioContract(for scenario: String) -> LabTerrainScanScenarioContract? {
    switch scenario {
    case "terrain_scan_smoke":
        return LabTerrainScanScenarioContract(
            scenario: scenario,
            agentX: 8,
            agentZ: 8,
            radius: 1,
            relation: "around_below",
            order: "dz_then_dx",
            expectedCellsPlanned: 9,
            expectedCellsObserved: 9,
            expectedUniqueChunks: nil,
            requiresChunkBoundaryCrossing: false
        )
    case "terrain_scan_edge_smoke":
        return LabTerrainScanScenarioContract(
            scenario: scenario,
            agentX: 16,
            agentZ: 16,
            radius: 1,
            relation: "around_below",
            order: "dz_then_dx",
            expectedCellsPlanned: 9,
            expectedCellsObserved: 9,
            expectedUniqueChunks: 4,
            requiresChunkBoundaryCrossing: true
        )
    default:
        return nil
    }
}

func isTerrainScanScenario(_ scenario: String) -> Bool {
    terrainScanScenarioContract(for: scenario) != nil
}
