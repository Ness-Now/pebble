import PebbleAgents
import PebbleCore

struct PebbleAgentPhysicalGestureMarker {
    let signalID: String
    let sourcePosition: AgentPosition
    let pointedPosition: AgentPosition
    let expiresAtTick: Int
}

/// Read-only physical adapter. It samples a bounded set of loaded voxels and
/// returns raw evidence; social meaning remains exclusively in PebbleAgents.
struct PebbleAgentPhysicalSignalAdapter {
    func observe(
        world: World,
        snapshot: AgentPhysicalChannelSnapshot,
        agents: [AgentSnapshot],
        atTick tick: Int
    ) -> [AgentPhysicalSignalObservation] {
        guard snapshot.enabled else { return [] }
        let config = snapshot.configuration
        return snapshot.signals.filter {
            $0.status == .pending && $0.emittedAtTick < tick && tick <= $0.expiresAtTick
        }.sorted { $0.signalID < $1.signalID }.flatMap { signal in
            agents.filter { $0.id != signal.senderID.rawValue }.sorted {
                $0.id < $1.id
            }.map { observer in
                observation(
                    world: world,
                    signal: signal,
                    observer: observer,
                    configuration: config,
                    tick: tick
                )
            }
        }
    }

    private func observation(
        world: World,
        signal: AgentPhysicalSignal,
        observer: AgentSnapshot,
        configuration: AgentPhysicalChannelConfiguration,
        tick: Int
    ) -> AgentPhysicalSignalObservation {
        let distance = manhattan(signal.sourcePosition, observer.position)
        let geometry = sampleGeometry(
            world: world,
            from: signal.sourcePosition,
            to: observer.position,
            maximumSamples: configuration.maximumOcclusionSamples
        )
        let sound = geometry.chunksReady
            ? configuration.soundClarity(
                distanceManhattan: distance,
                opaqueOcclusionCount: geometry.opaqueOcclusionCount
            )
            : 0
        let gesture = geometry.chunksReady
            ? configuration.gestureClarity(
                distanceManhattan: distance,
                lineOfSight: geometry.lineOfSight
            )
            : 0
        return AgentPhysicalSignalObservation(
            signalID: signal.signalID,
            observerID: AgentID(rawValue: observer.id)!,
            distanceManhattan: distance,
            soundClarity: sound,
            gestureClarity: gesture,
            opaqueOcclusionCount: geometry.opaqueOcclusionCount,
            lineOfSight: geometry.lineOfSight,
            chunksReady: geometry.chunksReady,
            observedAtTick: tick
        )
    }

    private func sampleGeometry(
        world: World,
        from source: AgentPosition,
        to observer: AgentPosition,
        maximumSamples: Int
    ) -> (chunksReady: Bool, opaqueOcclusionCount: Int, lineOfSight: Bool) {
        guard world.isChunkReady(source.x >> 4, source.z >> 4),
              world.isChunkReady(observer.x >> 4, observer.z >> 4) else {
            return (false, 0, false)
        }
        let start = AgentPosition(x: source.x, y: source.y + 1, z: source.z)
        let end = AgentPosition(x: observer.x, y: observer.y + 1, z: observer.z)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        let steps = max(abs(dx), abs(dy), abs(dz))
        guard steps > 1 else { return (true, 0, true) }
        let sampleCount = min(maximumSamples, steps - 1)
        var sampled = Set<AgentPosition>()
        var occlusions = 0
        for index in 1...sampleCount {
            let numerator = index * steps / (sampleCount + 1)
            let position = AgentPosition(
                x: start.x + dx * numerator / steps,
                y: start.y + dy * numerator / steps,
                z: start.z + dz * numerator / steps
            )
            guard sampled.insert(position).inserted else { continue }
            guard world.isChunkReady(position.x >> 4, position.z >> 4) else {
                return (false, occlusions, false)
            }
            let fingerprint = world.getBlock(position.x, position.y, position.z)
            let blockID = fingerprint >> 4
            if blockDefs.indices.contains(blockID), blockDefs[blockID].opaque {
                occlusions += 1
            }
        }
        return (true, occlusions, occlusions == 0)
    }

    private func manhattan(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }
}
