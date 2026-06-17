import Foundation

struct LabAgent: Encodable {
    let id: String
    let type: String
    var state: String
    var position: LabAgentPosition
    var needs: LabAgentNeeds
    let tickCreated: Int
    var ticksAlive: Int

    init(id: String, x: Int, y: Int, z: Int) {
        self.id = id
        type = "abstract_lab_agent"
        state = "idle"
        position = LabAgentPosition(x: x, y: y, z: z)
        needs = LabAgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.5, safety: 1)
        tickCreated = 0
        ticksAlive = 0
    }

    mutating func tick() {
        needs.hunger += 0.01
        needs.fatigue += 0.005
        state = "idle"
        ticksAlive += 1
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
