import PebbleAgents
import PebbleCore

struct PebbleAgentConstructionSiteDiagnostics {
    var candidatesConsidered = 0
    var positionsRead = 0
    var chunkRejected = 0
    var floorRejected = 0
    var replaceableRejected = 0
    var liquidRejected = 0
    var naturalRejected = 0
    var reservedRejected = 0
    var workRejected = 0
    var occupancyRejected = 0
    var routeRejected = 0
    var maximumWorkPositionsFound = 0
    var bestOrigin: AgentPosition?
    var bestFlags = "none"
    var selectedOrigin: AgentPosition?
    var lastFailure = "none"
}

struct PebbleAgentConstructionSiteSelection {
    let project: AgentConstructionProject
    let candidate: AgentConstructionSiteCandidate
    let diagnostics: PebbleAgentConstructionSiteDiagnostics
}

enum PebbleAgentConstructionMapping {
    static let woodFingerprint = Int(cell(B.oak_log))
    static let stoneFingerprint = Int(cell(B.stone))

    static func fingerprint(for resource: AgentResourceKind) -> Int? {
        switch resource {
        case .wood: return woodFingerprint
        case .stone: return stoneFingerprint
        case .sandboxResource, .foodRaw: return nil
        }
    }
}

struct PebbleAgentConstructionSiteAdapter {
    static let maximumHorizontalDistance = AgentConstructionSiteSelector.maximumHorizontalDistance
    static let maximumCandidateCount = AgentConstructionSiteSelector.maximumCandidateCount
    static let maximumDirectBlockReadsPerCandidate = 64

    private struct Inspection {
        let candidate: AgentConstructionSiteCandidate
        let workPositions: [AgentPosition]
    }

    enum SiteError: Error, CustomStringConvertible {
        case builderAwayFromHome
        case noSafeBuildSite

        var description: String {
            switch self {
            case .builderAwayFromHome: return "construction setup requires builder at home"
            case .noSafeBuildSite: return "noSafeBuildSite"
            }
        }
    }

    private let navigationAdapter = PebbleAgentNavigationAdapter()

    func select(
        world: World,
        builder: AgentSnapshot,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition,
        tick: Int,
        diagnostics: inout PebbleAgentConstructionSiteDiagnostics
    ) throws -> PebbleAgentConstructionSiteSelection {
        guard builder.position == builder.homePosition else {
            throw SiteError.builderAwayFromHome
        }
        let blueprint = AgentBlueprint.fixedLeanToV1
        diagnostics = PebbleAgentConstructionSiteDiagnostics()
        var candidates: [AgentConstructionSiteCandidate] = []
        var inspections: [Inspection] = []
        for (index, origin) in candidateOrigins(
            world: world,
            home: builder.homePosition
        ).enumerated() {
            diagnostics.candidatesConsidered += 1
            let inspection = inspect(
                world: world,
                builder: builder,
                blueprint: blueprint,
                origin: origin,
                candidateIndex: index,
                occupiedAgentPositions: occupiedAgentPositions,
                playerPosition: playerPosition
            )
            let inspected = inspection.candidate
            diagnostics.positionsRead += inspected.positionsRead
            if !inspected.chunksReady { diagnostics.chunkRejected += 1 }
            if !inspected.solidFloor { diagnostics.floorRejected += 1 }
            if !inspected.replaceableCells { diagnostics.replaceableRejected += 1 }
            if !inspected.liquidFree { diagnostics.liquidRejected += 1 }
            if !inspected.naturalResourcesClear { diagnostics.naturalRejected += 1 }
            if !inspected.reservedSpacesClear { diagnostics.reservedRejected += 1 }
            if !inspected.workPositionsClear { diagnostics.workRejected += 1 }
            if !inspected.occupancyClear { diagnostics.occupancyRejected += 1 }
            if !inspected.routeFound { diagnostics.routeRejected += 1 }
            if inspection.workPositions.count > diagnostics.maximumWorkPositionsFound {
                diagnostics.maximumWorkPositionsFound = inspection.workPositions.count
                diagnostics.bestOrigin = inspected.origin
                diagnostics.bestFlags = "floor=\(inspected.solidFloor ? 1 : 0),replaceable=\(inspected.replaceableCells ? 1 : 0),natural=\(inspected.naturalResourcesClear ? 1 : 0),reserved=\(inspected.reservedSpacesClear ? 1 : 0),occupancy=\(inspected.occupancyClear ? 1 : 0),route=\(inspected.routeFound ? 1 : 0)"
            }
            candidates.append(inspected)
            inspections.append(inspection)
        }
        guard let selected = try AgentConstructionSiteSelector.select(
            home: builder.homePosition,
            candidates: candidates
        ) else {
            diagnostics.lastFailure = "noSafeBuildSite"
            throw SiteError.noSafeBuildSite
        }
        diagnostics.selectedOrigin = selected.origin
        guard let selectedWorkPositions = inspections.first(where: {
            $0.candidate.origin == selected.origin
        })?.workPositions else {
            diagnostics.lastFailure = "noSafeBuildSite"
            throw SiteError.noSafeBuildSite
        }
        let projectId = "fixedLeanToV1:\(builder.id):\(tick):\(positionText(selected.origin))"
        let project = try AgentConstructionProject(
            projectId: projectId,
            blueprint: blueprint,
            builderAgentId: builder.id,
            origin: selected.origin,
            createdAtTick: tick,
            previousHomePosition: builder.homePosition,
            originalFingerprints: selected.originalFingerprints,
            workPositions: selectedWorkPositions,
            materialAuthority: .physicalCustody
        )
        return PebbleAgentConstructionSiteSelection(
            project: project,
            candidate: selected,
            diagnostics: diagnostics
        )
    }

    private func inspect(
        world: World,
        builder: AgentSnapshot,
        blueprint: AgentBlueprint,
        origin: AgentPosition,
        candidateIndex: Int,
        occupiedAgentPositions: [AgentPosition],
        playerPosition: AgentPosition
    ) -> Inspection {
        var reads = 0
        var blockCache: [AgentPosition: Int] = [:]
        func ready(_ position: AgentPosition) -> Bool {
            world.isChunkReady(position.x >> 4, position.z >> 4)
        }
        func read(_ position: AgentPosition) -> Int? {
            guard ready(position) else { return nil }
            if let cached = blockCache[position] { return cached }
            reads += 1
            let fingerprint = world.getBlock(position.x, position.y, position.z)
            blockCache[position] = fingerprint
            return fingerprint
        }
        func offset(_ relative: AgentPosition) -> AgentPosition {
            AgentPosition(
                x: origin.x + relative.x,
                y: origin.y + relative.y,
                z: origin.z + relative.z
            )
        }
        let targets = blueprint.cells.map { ($0, offset($0.relativePosition)) }
        let entrance = offset(blueprint.entranceOffset)
        let rest = offset(blueprint.restOffset)
        let allRelevant = targets.map(\.1)
            + [entrance, rest]
            + (0..<blueprint.footprintWidth).flatMap { x in
                (0..<blueprint.footprintDepth).map { z in
                    AgentPosition(x: origin.x + x, y: origin.y - 1, z: origin.z + z)
                }
            }
        let chunksReady = allRelevant.allSatisfy(ready)
        var originalFingerprints: [AgentConstructionCellFingerprint] = []
        var replaceableCells = chunksReady
        var liquidFree = chunksReady
        var naturalResourcesClear = chunksReady
        for (cell, target) in targets {
            guard let fingerprint = read(target) else {
                replaceableCells = false
                liquidFree = false
                naturalResourcesClear = false
                continue
            }
            originalFingerprints.append(AgentConstructionCellFingerprint(
                cellIndex: cell.index,
                originalFingerprint: fingerprint
            ))
            let id = fingerprint >> 4
            replaceableCells = replaceableCells && blockDefs[id].replaceable
            liquidFree = liquidFree && id != Int(B.water) && id != Int(B.lava)
            naturalResourcesClear = naturalResourcesClear
                && PebbleAgentNaturalResourceMapping.resource(for: fingerprint) == nil
        }
        var solidFloor = chunksReady
        for x in 0..<blueprint.footprintWidth {
            for z in 0..<blueprint.footprintDepth {
                let position = AgentPosition(
                    x: origin.x + x,
                    y: origin.y - 1,
                    z: origin.z + z
                )
                guard let fingerprint = read(position) else {
                    solidFloor = false
                    continue
                }
                solidFloor = solidFloor && blockDefs[fingerprint >> 4].solid
            }
        }
        func bodySpaceClear(_ position: AgentPosition) -> Bool {
            guard let feet = read(position),
                  let head = read(AgentPosition(x: position.x, y: position.y + 1, z: position.z)) else {
                return false
            }
            return isAir(UInt16(truncatingIfNeeded: feet))
                && isAir(UInt16(truncatingIfNeeded: head))
        }
        let reservedSpacesClear = bodySpaceClear(entrance) && bodySpaceClear(rest)
        let occupied = Set(occupiedAgentPositions + [playerPosition, builder.position])
        var workPositions: [AgentPosition] = []
        for (cell, target) in targets {
            let blockedBodyColumns: [AgentPosition] = blueprint.cells.prefix(cell.index).compactMap {
                let placed = offset($0.relativePosition)
                guard placed.y == origin.y || placed.y == origin.y + 1 else { return nil }
                return AgentPosition(x: placed.x, y: origin.y, z: placed.z)
            }
            let previouslyBlockedBodyColumns = Set(blockedBodyColumns)
            let preferred = offset(cell.workOffset)
            let workCandidates = [preferred] + AgentCardinalDirection.allCases.map { direction in
                AgentPosition(
                    x: target.x + direction.dx,
                    y: origin.y,
                    z: target.z + direction.dz
                )
            }
            var seen = Set<AgentPosition>()
            let selectedWork = workCandidates.first { position in
                guard seen.insert(position).inserted,
                      !previouslyBlockedBodyColumns.contains(position),
                      !occupied.contains(position),
                      ready(position),
                      let below = read(AgentPosition(
                          x: position.x,
                          y: position.y - 1,
                          z: position.z
                      )),
                      blockDefs[below >> 4].solid,
                      bodySpaceClear(position) else { return false }
                let horizontal = abs(target.x - position.x) + abs(target.z - position.z)
                let vertical = target.y - position.y
                return horizontal == 1 && (0...2).contains(vertical)
            }
            if let selectedWork { workPositions.append(selectedWork) }
        }
        let workPositionsClear = workPositions.count == blueprint.cells.count
        let forbiddenOccupancy = Set(targets.map(\.1) + workPositions + [entrance, rest])
        let occupancyClear = occupied.isDisjoint(with: forbiddenOccupancy)
        let routeFound: Bool
        if let firstWork = workPositions.first, workPositionsClear {
            let routeObservation = navigationAdapter.observe(
                world: world,
                agent: builder,
                target: firstWork,
                occupiedAgentPositions: occupiedAgentPositions + [playerPosition],
                goalMode: .exact
            )
            routeFound = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                start: builder.position,
                target: firstWork,
                goalMode: .exact,
                cells: routeObservation.cells,
                radius: routeObservation.radius,
                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
            )).found
        } else {
            routeFound = false
        }
        let candidate = AgentConstructionSiteCandidate(
            origin: origin,
            candidateIndex: candidateIndex,
            chunksReady: chunksReady,
            solidFloor: solidFloor,
            replaceableCells: replaceableCells,
            liquidFree: liquidFree,
            naturalResourcesClear: naturalResourcesClear,
            reservedSpacesClear: reservedSpacesClear,
            workPositionsClear: workPositionsClear,
            occupancyClear: occupancyClear,
            routeFound: routeFound,
            positionsRead: reads,
            originalFingerprints: originalFingerprints
        )
        return Inspection(candidate: candidate, workPositions: workPositions)
    }

    private func candidateOrigins(world: World, home: AgentPosition) -> [AgentPosition] {
        var offsets: [(dx: Int, dz: Int, direction: Int)] = []
        for dx in -Self.maximumHorizontalDistance...Self.maximumHorizontalDistance {
            for dz in -Self.maximumHorizontalDistance...Self.maximumHorizontalDistance {
                let distance = abs(dx) + abs(dz)
                guard distance > 0, distance <= Self.maximumHorizontalDistance else { continue }
                let target = AgentPosition(
                    x: home.x + dx,
                    y: home.y,
                    z: home.z + dz
                )
                let direction = AgentResourcePerception.direction(
                    observerPosition: home,
                    target: target
                ).flatMap { AgentCardinalDirection.allCases.firstIndex(of: $0) } ?? 0
                offsets.append((dx, dz, direction))
            }
        }
        offsets.sort {
            let lhsDistance = abs($0.dx) + abs($0.dz)
            let rhsDistance = abs($1.dx) + abs($1.dz)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            if $0.direction != $1.direction { return $0.direction < $1.direction }
            if $0.dx != $1.dx { return $0.dx < $1.dx }
            return $0.dz < $1.dz
        }
        return offsets.prefix(Self.maximumCandidateCount).map {
            let x = home.x + $0.dx
            let z = home.z + $0.dz
            let y = world.isChunkReady(x >> 4, z >> 4)
                ? world.surfaceY(x, z)
                : home.y
            return AgentPosition(x: x, y: y, z: z)
        }
    }

    private func positionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
