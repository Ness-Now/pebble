import Foundation
import PebbleAgents

func runPebbleAgentsMortalityPopulationExitSmoke() {
    section("pebble agents mortality and population exit")

    let live = AgentMortalityConfiguration.live
    check("mortality configuration defaults", live.maximumDeathsPerTick == 8
        && live.maximumRetainedDeathRecords == 32
        && live.maximumFinalMemoryEntries == 8
        && live.maximumCancelledCommitmentIDsPerDeath == 32
        && live.maximumExitFrames == 32)
    check("mortality rejects zero deaths per tick", {
        do {
            _ = try AgentMortalityConfiguration(maximumDeathsPerTick: 0)
            return false
        } catch AgentMortalityError.invalidConfiguration("deaths per tick") {
            return true
        } catch { return false }
    }())
    check("mortality rejects oversized death history", {
        do {
            _ = try AgentMortalityConfiguration(maximumRetainedDeathRecords: 65)
            return false
        } catch AgentMortalityError.invalidConfiguration("death records") {
            return true
        } catch { return false }
    }())
    check("mortality accepts zero final memories", (try? AgentMortalityConfiguration(
        maximumFinalMemoryEntries: 0
    )) != nil)
    check("mortality rejects oversized final memories", (try? AgentMortalityConfiguration(
        maximumFinalMemoryEntries: 17
    )) == nil)
    check("mortality accepts zero commitment IDs", (try? AgentMortalityConfiguration(
        maximumCancelledCommitmentIDsPerDeath: 0
    )) != nil)
    check("mortality rejects oversized exit history", (try? AgentMortalityConfiguration(
        maximumExitFrames: 65
    )) == nil)
    check("mortality configuration Codable", {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let bytes = try? encoder.encode(live),
              let decoded = try? JSONDecoder().decode(
                  AgentMortalityConfiguration.self,
                  from: bytes
              ) else { return false }
        return decoded == live
    }())
    check("mortality cause V1 is starvation only", AgentMortalityCause.allCases == [.starvation])
    check("death ID validates canonical form", AgentDeathID(
        rawValue: "death-agent_3-t33-0123456789abcdef"
    ) != nil)
    check("death ID rejects path punctuation", AgentDeathID(rawValue: "death/agent_3") == nil)

    let historical = AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [AgentResourceAmount(resource: .wood, quantity: 2)],
        campStock: []
    )
    check("mortality-off conservation remains exact", historical.balanced
        && historical.unrecoveredAtDeathTotal == 0)
    let terminal = AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [],
        campStock: [],
        unrecoveredAtDeath: [AgentResourceAmount(resource: .wood, quantity: 2)]
    )
    check("mortality terminal custody conserves resources", terminal.balanced
        && terminal.unrecoveredAtDeathTotal == 2)
    check("mortality terminal custody cannot hide duplication", !AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [AgentResourceAmount(resource: .wood, quantity: 1)],
        campStock: [],
        unrecoveredAtDeath: [AgentResourceAmount(resource: .wood, quantity: 2)]
    ).balanced)
}
