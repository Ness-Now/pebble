import Foundation
import PebbleCore

struct LabAgent: Encodable {
    let id: String
    let type: String
    var state: String
    var position: LabAgentPosition
    var needs: LabAgentNeeds
    var observation: LabAgentObservation?
    var lastAction: LabAgentAction?
    let tickCreated: Int
    var ticksAlive: Int
    var observationCount: Int
    var actionCount: Int

    init(id: String, x: Int, y: Int, z: Int) {
        self.id = id
        type = "abstract_lab_agent"
        state = "idle"
        position = LabAgentPosition(x: x, y: y, z: z)
        needs = LabAgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.5, safety: 1)
        observation = nil
        lastAction = nil
        tickCreated = 0
        ticksAlive = 0
        observationCount = 0
        actionCount = 0
    }

    mutating func tick() {
        needs.hunger += 0.01
        needs.fatigue += 0.005
        state = "idle"
        ticksAlive += 1
    }

    mutating func observe(world: World) {
        let x = position.x
        let y = position.y
        let z = position.z
        let chunkX = floorDiv(x, CHUNK_W)
        let chunkZ = floorDiv(z, CHUNK_W)
        observation = LabAgentObservation(
            x: x,
            y: y,
            z: z,
            chunkX: chunkX,
            chunkZ: chunkZ,
            chunkReady: world.isChunkReady(chunkX, chunkZ),
            surfaceY: world.surfaceY(x, z),
            height: world.heightAt(x, z),
            blockBelow: world.getBlock(x, y - 1, z),
            blockAtFeet: world.getBlock(x, y, z)
        )
        observationCount += 1
    }

    mutating func decideAction(tick: Int) {
        let action: LabAgentAction
        if needs.fatigue >= 0.02 {
            action = LabAgentAction(name: "rest", reason: "fatigue >= 0.02", tick: tick)
        } else if needs.curiosity >= 0.5 {
            action = LabAgentAction(name: "observe_area", reason: "curiosity >= 0.5", tick: tick)
        } else {
            action = LabAgentAction(name: "wait", reason: "default", tick: tick)
        }

        lastAction = action
        actionCount += 1
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case state
        case position
        case needs
        case observation
        case lastAction
        case tickCreated
        case ticksAlive
        case actionCount
    }
}

struct LabAgentPosition: Encodable {
    let x: Int
    let y: Int
    let z: Int
}

struct LabAgentNeeds: Encodable {
    var hunger: Double
    var fatigue: Double
    var curiosity: Double
    var safety: Double
}

struct LabAgentObservation: Encodable {
    let x: Int
    let y: Int
    let z: Int
    let chunkX: Int
    let chunkZ: Int
    let chunkReady: Bool
    let surfaceY: Int
    let height: Int
    let blockBelow: Int?
    let blockAtFeet: Int?
}

struct LabAgentAction: Encodable {
    let name: String
    let reason: String
    let tick: Int
}
