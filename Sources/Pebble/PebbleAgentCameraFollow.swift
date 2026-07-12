import Foundation
import PebbleCore

enum PebbleAgentFollowMode: Equatable {
    case off
    case focusedAgent
    case fixedAgent(String)

    var statusText: String {
        switch self {
        case .off:
            return "off"
        case .focusedAgent:
            return "focus"
        case let .fixedAgent(agentId):
            return agentId
        }
    }
}

struct PebbleAgentCameraFollow {
    @discardableResult
    func orient(player: Player, toward probe: LabCoreAgentEntity) -> Bool {
        let dx = probe.x - player.x
        let dy = probe.centerY() - player.eyeY()
        let dz = probe.z - player.z
        let horizontalDistance = (dx * dx + dz * dz).squareRoot()
        guard horizontalDistance > 0.000_001 || abs(dy) > 0.000_001 else { return false }

        let yaw = atan2(-dx, dz)
        let pitchLimit = Double.pi / 2 - 0.001
        let pitch = max(-pitchLimit, min(pitchLimit, atan2(-dy, horizontalDistance)))
        guard yaw.isFinite, pitch.isFinite else { return false }

        player.yaw = yaw
        player.pitch = pitch
        return true
    }
}
