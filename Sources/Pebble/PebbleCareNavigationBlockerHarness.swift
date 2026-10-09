import Foundation
import PebbleAgents
import PebbleCore

/// Bounded read-only qualification around ordinary founder/World entry,
/// simulation, save and exit. No prerequisite, pair or birth is supplied.
enum PebbleCareNavigationBlockerHarness {
    static func runIfRequested() -> Int32? {
        let env = ProcessInfo.processInfo.environment
        guard let phase = env["PEBBLELAB_PS01_CARE_NAVIGATION_PHASE"] else { return nil }
        do {
            guard let home = env["CFFIXED_USER_HOME"], home.hasPrefix("/tmp/"),
                  let output = env["PEBBLELAB_PS01_CARE_NAVIGATION_OUTPUT"],
                  let seed = env["PEBBLELAB_PS01_CARE_NAVIGATION_SEED"],
                  ["read", "contract"].contains(phase) else {
                throw Failure.refused("explicit isolated qualification configuration required")
            }
            if phase == "contract" { try contract(output: output) }
            else { try run(phase: phase, seed: seed, output: output) }
            print("[ps01-care] PASS phase=\(phase)")
            return 0
        } catch {
            fputs("[ps01-care] FAIL \(error)\n", stderr)
            return 1
        }
    }

    private static func run(phase: String, seed: String, output: String) throws {
        let game = GameCore()
        let controller = PebbleAgentController()
        game.settings.renderDistance = 4
        controller.worldSideReceiptDatabase = game.db
        controller.installWorldContinuation(on: game)
        game.physicalSimulationCoverageProvider = { [weak controller] world in
            controller?.physicalSimulationCoverageRequest(for: world) ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak controller, weak game] in
            guard let controller, let game else { return false }
            return controller.prepareForLifecyclePersistence(world: game.world)
        }
        game.finalizeExternalLifecycleState = { [weak controller] in
            controller?.finalizeLifecycleAfterPersistence()
        }
        let id = "ps01-i09-seed-\(seed)-founders-24"
        var assertions = 0
        func require(_ condition: Bool, _ reason: String) throws {
            assertions += 1
            guard condition else { throw Failure.refused(reason + " error=" + (controller.lastError ?? "none")) }
            print("[ps01-care] assertion=\(assertions) PASS \(reason)")
        }
        let beforeRestore = try Data(contentsOf: URL(fileURLWithPath: output + ".session.json"))
        game.loadWorld(id)
        try require(game.hasWorld() && game.worldContinuationReady && controller.session != nil,
                    "fresh process ordinary World entry restores")
        try require(try controller.session!.durableStateBytes() == beforeRestore,
                    "exact authoritative state restores including accepted plans and births")
        let loadedBirths = controller.session!.birthsSnapshot()
        try exactBodies(controller, game, require)
        let horizon = Int(ProcessInfo.processInfo.environment["PEBBLELAB_PS01_CARE_NAVIGATION_TICKS"] ?? "40")!
        guard phase == "read", horizon >= 0, horizon <= 200 else { throw Failure.refused("bounded evaluation read only") }
        func sample(_ label: String, full: Bool) throws {
            let state = controller.session!
            let before = try state.durableStateBytes()
            let evidence: [String: Any] = ["label": label, "worldTick": game.world.time, "tick": state.tick, "runtimeErrors": controller.runtimeErrorCount, "droppedCatchUpSteps": controller.droppedCatchUpSteps, "reproduction": try JSONSerialization.jsonObject(with: JSONEncoder().encode(state.reproductionSnapshot())), "physicalBodies": game.world.entities.compactMap { ($0 as? LabCoreAgentEntity)?.labAgentId }.sorted(), "carried": controller.probesByAgentId.keys.sorted().map { id in ["agentID": id, "items": controller.probesByAgentId[id]!.carriedItems.compactMap { $0 }.map { ["item": itemName($0.id), "count": $0.count] as [String: Any] }] as [String: Any] }]
            let data = try JSONSerialization.data(withJSONObject: evidence, options: [.sortedKeys])
            let url = URL(fileURLWithPath: output + ".samples.ndjson")
            if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
            let handle = try FileHandle(forWritingTo: url); try handle.seekToEnd(); try handle.write(contentsOf: data + Data([10])); try handle.close()
            if full { try before.write(to: URL(fileURLWithPath: output + ".sample-\(game.world.time).session.json"), options: .atomic) }
            guard try state.durableStateBytes() == before else { throw Failure.refused("measurement mutation") }
        }
        try sample("loaded", full: true)
        try careProbe(game, controller, output: output + ".loaded-route.json")
        let initialState = try JSONSerialization.jsonObject(with: controller.session!.durableStateBytes()) as! [String: Any]
        let initialParent = (initialState["agents"] as! [[String: Any]]).first { $0["agentID"] as? String == "agent_18" }!
        let initialMoves = initialParent["movementCount"] as! Int
        var previousCounts = ""
        for elapsed in 0..<horizon {
            try step(game, controller, id: id)
            try exactBodies(controller, game, require, printAssertion: false)
            let session = controller.session!
            let counts = "\(session.birthsSnapshot().count):\(session.snapshot().agents.count):\(session.lifecycleSummary().activePlanCount)"
            if elapsed % 5 == 4 || counts != previousCounts {
                try sample("progress", full: true)
            }
            previousCounts = counts
            if elapsed % 1200 == 0 {
                print("[ps01-care] progress world=\(game.world.time) tick=\(session.tick) living=\(session.snapshot().agents.count) meals=\(session.physicalFoodSurvivalSnapshot()!.totalConsumedQuantity) plans=\(session.lifecycleSummary().activePlanCount) births=\(session.lifecycleSummary().totalBirthCount)")
                fflush(stdout)
            }
        }
        try careProbe(game, controller, output: output + ".final-route.json")
        try sample("final-before-save", full: true)
        if horizon >= 60 {
            let finalState = try JSONSerialization.jsonObject(with: controller.session!.durableStateBytes()) as! [String: Any]
            let care = finalState["dependentCareState"] as! [String: Any]
            let outcomes = care["terminalOutcomes"] as! [[String: Any]]
            let resolved = outcomes.filter { $0["needID"] as? String == "care-need-00000005" && $0["terminalReason"] as? String == "supervised" }
            try require(resolved.count == 1, "authentic blocked supervision resolves exactly once through normal behavior")
            let parent = (finalState["agents"] as! [[String: Any]]).first { $0["agentID"] as? String == "agent_18" }!
            try require(parent["movementCount"] as! Int > initialMoves, "authentic guardian has new verified physical movement")
        }
        let session = controller.session!
        try require(loadedBirths.allSatisfy { session.birthsSnapshot().contains($0) },
                    "restart preserves every accepted birth identity and state")
        for birth in loadedBirths {
            let plan = session.lifecycleSnapshot().plans.first { $0.planID == birth.planID }!
            try require(plan.physicalSubsistenceEvidence?.meals.map(\.agentID) == birth.progenitorIDs,
                        "birth retains exact physical meals of canonical parents")
            try require(session.kinshipSnapshot().parentageRecords.contains {
                $0.childID == birth.newbornID && $0.canonicalParentIDs == birth.progenitorIDs
            } && session.genotype(for: birth.newbornID)?.contributorIDs == birth.progenitorIDs,
                        "kinship and inherited genetics retain birth provenance")
        }
        try require(session.populationSummary().capacity == 30,
                    "capacity remains exactly 30")
        let acquired = session.wildSubsistenceSnapshot().retainedOutcomes.reduce(0) { total, row in
            total + row.outcome.acquiredItems.filter { $0.identity.itemKey == "sweet_berries" }.reduce(0) { $0 + $1.count }
        }
        let consumed = session.physicalFoodSurvivalSnapshot()!.totalConsumedQuantity
        let carried = controller.probesByAgentId.values.reduce(0) { total, probe in
            total + probe.carriedItems.compactMap { $0 }.filter { itemName($0.id) == "sweet_berries" }.reduce(0) { $0 + $1.count }
        }
        try require(acquired == Int(consumed) + carried, "real acquisition equals consumed plus physical custody")
        try require(controller.runtimeErrorCount == 0 && controller.droppedCatchUpSteps == 0
            && controller.candidatePhysicalHardFailure == nil, "no runtime or physical integrity failure")
        let prefix = output + (phase == "read" ? ".read" : "")
        try session.durableStateBytes().write(
            to: URL(fileURLWithPath: prefix + ".before-save.session.json"), options: .atomic)
        // The existing checkpoint owner accepts all elapsed physical World
        // time, including a partial interval after the latest cognitive step.
        // Compare the complete saved state with that owning clock operation;
        // no prerequisite or reproductive transition is supplied here.
        var saveBoundary = session
        try saveBoundary.advancePhysiologicalTime(toWorldTick: game.world.time)
        let before = try saveBoundary.durableStateBytes()
        try require(game.saveAndFlush(), "ordinary Save/Continue succeeds")
        try require(try controller.session!.durableStateBytes() == before,
                    "Save/Continue equals authoritative World-time boundary")
        try before.write(to: URL(fileURLWithPath: prefix + ".session.json"), options: .atomic)
        let evidence: [String: Any] = ["phase": phase, "seed": seed, "founders": 24,
            "worldTick": game.world.time, "tick": session.tick,
            "births": session.birthsSnapshot().count, "population": session.snapshot().agents.count,
            "acquired": acquired, "consumed": consumed, "carried": carried,
            "checkpointSchema": try session.makeCheckpoint().schemaVersion,
            "semanticDigest": try saveBoundary.durableStateDigest().rawValue,
            "causalDigest": session.causalLedgerSnapshot().summary.digest]
        try JSONSerialization.data(withJSONObject: evidence, options: [.prettyPrinted, .sortedKeys])
            .write(to: URL(fileURLWithPath: prefix + ".json"), options: .atomic)
        try require(game.exitToTitle() && controller.session == nil && controller.probesByAgentId.isEmpty,
                    "ordinary Save/Exit succeeds with verified cleanup")
        print("[ps01-care] assertions=\(assertions) finalBirths=\(session.birthsSnapshot().count) schema=\(try session.makeCheckpoint().schemaVersion) probesFinal=0")
    }



    private static func contract(output: String) throws {
        registerAllBlocks(); registerAllItems(); registerAllEntities(); registerAllSystems()
        let world = World(dim: .overworld, seed: 19)
        for cz in -2...2 { for cx in -2...2 {
            let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)
            chunk.buildHeightmap(); chunk.status = .lit; world.setChunk(chunk)
        } }
        for x in -24...24 { for z in -24...24 { world.setBlock(x,63,z,Int(cell(B.stone)),SET_SILENT) } }
        world.applyPhysicalSimulationCoverage(.active([PhysicalSimulationCoverageRoot(id:"fixture",chunkX:0,chunkZ:0)]))
        var results: [[String:Any]]=[]
        func check(_ name:String,_ okay:Bool) throws {
            results.append(["name":name,"passed":okay]); print("[care-contract] \(okay ? "PASS" : "FAIL") \(name)")
            if !okay { throw Failure.refused(name) }
        }
        let origin=AgentPosition(x:0,y:64,z:0)
        func east() throws -> AgentWorldNeighborObservation {
            try PebbleAgentWorldSensor().observe(world:world,position:origin).neighbors.first { $0.direction == .east }!
        }
        for block in [B.sweet_berry_bush,B.oak_sapling] {
            world.setBlock(1,64,0,Int(cell(block)),SET_SILENT)
            let n=try east();let nav=PebbleAgentNavigationAdapter().observe(world:world,origin:origin,target:AgentPosition(x:2,y:64,z:0),occupiedAgentPositions:[])
            try check("noncolliding vegetation agrees across navigation and movement: \(blockDefs[Int(block)].name)",n.traversable && nav.cells.contains { $0.position == AgentPosition(x:1,y:64,z:0) && $0.status == .traversable })
        }
        for block in [B.stone,B.oak_leaves,B.water,B.lava,B.fire,B.powder_snow] {
            world.setBlock(1,64,0,Int(cell(block)),SET_SILENT)
            world.setBlock(1,65,0,Int(cell(block)),SET_SILENT)
            try check("collision/fluid/hazard refuses: \(blockDefs[Int(block)].name)",!(try east()).traversable)
        }
        world.setBlock(1,65,0,0,SET_SILENT)
        world.setBlock(1,64,0,0,SET_SILENT);world.setBlock(1,63,0,0,SET_SILENT)
        try check("unsupported terrain refuses",!(try east()).traversable)
        world.setBlock(1,60,0,Int(cell(B.stone)),SET_SILENT)
        let drop=try east();try check("illegal vertical/drop refuses",!drop.traversable && (drop.dangerousDrop || (drop.stepDelta ?? -3) < -1))
        world.setBlock(1,63,0,Int(cell(B.campfire)),SET_SILENT)
        try check("hazardous support refuses",!(try east()).traversable)
        world.setBlock(1,63,0,Int(cell(B.stone)),SET_SILENT)
        let foreign=Entity(world:world);foreign.setPos(1.5,64,0.5);world.addEntity(foreign)
        let occupied=assessEntityPlacement(in:world,at:EntityPlacementPosition(x:1,y:64,z:0),bodyWidth:0.6,bodyHeight:1.8)
        try check("unrelated real entity body occupancy refuses",occupied.rejections.contains(.entityCollision))
        try check("movement sensor preserves unrelated entity occupancy", !(try east()).traversable)
        let occupiedNav = PebbleAgentNavigationAdapter().observe(world:world,origin:origin,
            target:AgentPosition(x:2,y:64,z:0),occupiedAgentPositions:[])
        try check("navigation preserves unrelated entity occupancy", occupiedNav.cells.contains {
            $0.position == AgentPosition(x:1,y:64,z:0) && $0.status == .blocked })
        world.removeEntity(foreign)
        world.setBlock(1,64,0,Int(cell(B.sweet_berry_bush)),SET_SILENT)
        let probe=LabCoreAgentEntity(world:world,labAgentId:"care-contract",physicalId:"care-contract-body")
        probe.setPos(0.5,64,0.5);world.addEntity(probe)
        let body=PebbleAgentEmbodiment(probe:probe)
        let move=try PebbleAgentMovementExecutor().proveBoundedCoreStep(world:world,embodiment:body,
            destination:AgentPosition(x:1,y:64,z:0))
        try check("Core physically moves through berry vegetation and verifies rollback",
            move.reachedCoreNode && move.physicalMutationCount == 1 && move.rollbackVerified)
        let denied=try PebbleAgentMovementExecutor().proveBoundedCoreStep(world:world,embodiment:body,
            destination:AgentPosition(x:1,y:64,z:0),occupied:[AgentPosition(x:1,y:64,z:0)])
        try check("dependent/peer occupied Core node refuses without movement",
            denied.occupiedRefused && denied.physicalMutationCount == 0)
        // Genuine Core slowing is allowed. The adapter must not mistake its
        // partial displacement for a centered grid step or durable body.
        world.setBlock(0,64,0,Int(cell(B.sweet_berry_bush)),SET_SILENT)
        world.setBlock(1,64,0,0,SET_SILENT)
        let beforeSlow=probe.capturePhysicalState()
        probe.move(1,0,0)
        let slowEvidence:[String:Any]=["fromX":beforeSlow.x,"requestedDX":1,
            "actualX":probe.x,"targetX":1.5,"floorMatchesTarget":body.position == AgentPosition(x:1,y:64,z:0),
            "centerMatchesTarget":probe.x == 1.5,"coreRule":"sweet_berry_bush scales horizontal movement by 0.8"]
        try JSONSerialization.data(withJSONObject:slowEvidence,options:[.prettyPrinted,.sortedKeys])
            .write(to:URL(fileURLWithPath:output+".partial-movement.json"))
        try check("Core slowing can reach the target cell without its exact center",
            body.position == AgentPosition(x:1,y:64,z:0) && probe.x == 1.3)
        try check("partial Core fixture restores its complete physical state",probe.restorePhysicalState(beforeSlow))
        let partial=try PebbleAgentMovementExecutor().proveBoundedCoreStep(world:world,embodiment:body,
            destination:AgentPosition(x:1,y:64,z:0))
        try check("partial Core move is refused as success and exactly rolled back",
            partial.pathFound && !partial.reachedCoreNode && partial.physicalMutationCount == 1
                && partial.rollbackVerified && probe.capturePhysicalState() == beforeSlow)
        world.setBlock(0,64,0,0,SET_SILENT)
        world.removeEntity(probe);world.setBlock(1,64,0,0,SET_SILENT)
        for x in 3...5 { for z in -1...1 { for y in 64...65 {
            world.setBlock(x,y,z,Int(cell(B.stone)),SET_SILENT)
        } } }
        let enclosed=assessEntityPlacement(in:world,at:EntityPlacementPosition(x:4,y:64,z:0),bodyWidth:0.6,bodyHeight:1.8)
        let enclosedPath=findPath(world,0.5,64,0.5,4.5,64,0.5,600,true,
            within:PhysicalPathSearchDomain(coverage:world.physicalSimulationCoverage))
        let foundEnclosed:Bool
        if case .path = enclosedPath { foundEnclosed=true } else { foundEnclosed=false }
        try check("actually enclosed interaction site has no fabricated Core path",
            !enclosed.isValid && !foundEnclosed)
        for x in 3...5 { for z in -1...1 { for y in 64...65 { world.setBlock(x,y,z,0,SET_SILENT) } } }
        let diagonalTarget=AgentPosition(x:2,y:64,z:1)
        let diagonalSites=[AgentPosition(x:1,y:64,z:1),AgentPosition(x:2,y:64,z:0),
            AgentPosition(x:2,y:64,z:2),AgentPosition(x:3,y:64,z:1)]
        for site in diagonalSites { for y in 64...65 { world.setBlock(site.x,y,site.z,Int(cell(B.stone)),SET_SILENT) } }
        let diagonalDependent=LabCoreAgentEntity(world:world,labAgentId:"dependent-contract",physicalId:"dependent-contract-body")
        diagonalDependent.setPos(2.5,64,1.5);world.addEntity(diagonalDependent)
        let legalDiagonal=PebbleAgentNavigationAdapter.terrainAssessment(world:world,position:AgentPosition(x:1,y:64,z:0))
        let diagonalCells=[AgentNavigationCell(position:origin,status:.traversable),
            AgentNavigationCell(position:AgentPosition(x:1,y:64,z:0),status:legalDiagonal.isValid ? .traversable : .blocked),
            AgentNavigationCell(position:diagonalTarget,status:.blocked)]
        let diagonalPlan=AgentBoundedRoutePlanner.plan(AgentNavigationRequest(start:origin,target:diagonalTarget,
            goalMode:.chebyshevAdjacent,cells:diagonalCells))
        try check("Core-valid diagonal care site remains reachable with blocked cardinal sites",
            legalDiagonal.isValid && diagonalPlan.positions == [origin,AgentPosition(x:1,y:64,z:0)]
                && diagonalSites.allSatisfy { !PebbleAgentNavigationAdapter.terrainAssessment(world:world,position:$0).isValid })
        world.removeEntity(diagonalDependent)
        for site in diagonalSites { for y in 64...65 { world.setBlock(site.x,y,site.z,0,SET_SILENT) } }
        let domain=PhysicalPathSearchDomain(coverage:world.physicalSimulationCoverage)
        let budget=findPath(world,0.5,64,0.5,8.5,64,0.5,1,true,within:domain)
        try check("Core node budget remains uncertainty",budget == .nodeBudgetExhausted)
        world.applyPhysicalSimulationCoverage(.inactive)
        try check("unavailable coverage stays unknown",findPath(world,0.5,64,0.5,1.5,64,0.5,600,true,within:PhysicalPathSearchDomain(coverage:world.physicalSimulationCoverage)) == .coverageUnavailable)
        let unknown=try PebbleAgentWorldSensor().observe(world:world,position:origin)
        try check("unavailable coverage cannot certify prospective recovery",unknown.physicalMovementAssessmentVersion == nil)
        let edge=try PebbleAgentWorldSensor().observe(world:world,position:AgentPosition(x:1000,y:64,z:1000))
        try check("unavailable chunks never traversable",edge.neighbors.allSatisfy { !$0.traversable && !$0.column.chunkReady })
        try JSONSerialization.data(withJSONObject:results,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:output+".contract.json"))
        print("[care-contract] assertions=\(results.count) failed=0 fixtureOnly=true")
    }

    private static func careProbe(_ game: GameCore, _ controller: PebbleAgentController, output: String) throws {
        let before = try controller.session!.durableStateBytes()
        let physicalBefore = controller.probesByAgentId.mapValues { $0.capturePhysicalState() }
        let timeBefore = game.world.time
        let agents = controller.session!.snapshot().agents
        guard let parent = agents.first(where: { $0.id == "agent_18" }),
              let dependent = agents.first(where: { $0.id == "agent_24" }),
              let body = controller.probesByAgentId[parent.id] else { throw Failure.refused("care actors missing") }
        func p(_ x: Int, _ y: Int, _ z: Int) -> [String: Int] { ["x":x,"y":y,"z":z] }
        func boxes(_ b: AABB) -> [String: Double] { ["x0":b.x0,"y0":b.y0,"z0":b.z0,"x1":b.x1,"y1":b.y1,"z1":b.z1] }
        func geometry() -> [[String: Any]] {
            var rows: [[String: Any]] = []
            for x in 198...210 { for z in -42 ... -29 { for y in 64...77 {
                guard game.world.isChunkReady(x >> 4, z >> 4) else { continue }
                let v = game.world.getBlock(x,y,z)
                rows.append(["position":p(x,y,z),"block":v,"name":blockDefs[v >> 4].name])
            } } }
            return rows
        }
        let geom = geometry()
        let geomBefore = try JSONSerialization.data(withJSONObject: geom, options: [.sortedKeys])
        let observation = PebbleAgentNavigationAdapter().observe(world: game.world, agent: parent, target: dependent.position, occupiedAgentPositions: agents.filter { $0.id != parent.id }.map(\.position), goalMode: .cardinalAdjacent)
        let coarse = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(start: parent.position, target: dependent.position, goalMode: .cardinalAdjacent, cells: observation.cells, radius: observation.radius, maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes, maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps))
        var candidates: [[String: Any]] = []
        for dx in -1...1 { for dy in -1...1 { for dz in -1...1 {
            if dx == 0 && dy == 0 && dz == 0 { continue }
            let x=dependent.position.x+dx, y=dependent.position.y+dy, z=dependent.position.z+dz
            let assessment = assessEntityPlacement(in: game.world, at: EntityPlacementPosition(x:x,y:y,z:z), bodyWidth:0.6, bodyHeight:1.8, ignoringEntityIDs:[body.id])
            var row: [String: Any] = ["position":p(x,y,z),"placementRejections":assessment.rejections.map(\.rawValue),"placementValid":assessment.isValid,"interactionChebyshevDistance":max(abs(dx),abs(dy),abs(dz)),"navigationManhattanDistance":abs(dx)+abs(dy)+abs(dz),"body":boxes(assessment.body)]
            let result = findPath(game.world, body.x,body.y,body.z,Double(x)+0.5,Double(y),Double(z)+0.5,600,true,within:PhysicalPathSearchDomain(coverage:game.world.physicalSimulationCoverage))
            switch result {
            case .path(let path):
                row["coreResult"]="path"
                row["path"]=path.map { p($0.x,$0.y,$0.z) }
                var edgeRows: [[String: Any]]=[]
                var lastX=body.x, lastY=body.y, lastZ=body.z
                for node in path {
                    let site=assessEntityPlacement(in:game.world,at:EntityPlacementPosition(x:node.x,y:node.y,z:node.z),bodyWidth:0.6,bodyHeight:1.8,ignoringEntityIDs:[body.id])
                    let dx=Double(node.x)+0.5-lastX, dy=Double(node.y)-lastY, dz=Double(node.z)+0.5-lastZ
                    let start=AABB(lastX-0.3,lastY,lastZ-0.3,lastX+0.3,lastY+1.8,lastZ+0.3)
                    let swept=AABB(min(start.x0,start.x0+dx),min(start.y0,start.y0+dy),min(start.z0,start.z0+dz),max(start.x1,start.x1+dx),max(start.y1,start.y1+dy),max(start.z1,start.z1+dz))
                    var collisionBoxes:[AABB]=[]
                    game.world.forEachCollisionBox(swept) { collisionBoxes.append($0) }
                    // Pure Core sweep functions, no Entity.move or body mutation.
                    var clippedY=dy; for b in collisionBoxes { clippedY=sweepY(start,b,clippedY) }
                    let afterY=AABB(start.x0,start.y0+clippedY,start.z0,start.x1,start.y1+clippedY,start.z1)
                    var clippedX=dx; for b in collisionBoxes { clippedX=sweepX(afterY,b,clippedX) }
                    let afterX=AABB(afterY.x0+clippedX,afterY.y0,afterY.z0,afterY.x1+clippedX,afterY.y1,afterY.z1)
                    var clippedZ=dz; for b in collisionBoxes { clippedZ=sweepZ(afterX,b,clippedZ) }
                    let occupants=game.world.getEntitiesInBox(swept).filter { $0.id != body.id }.map { ["id":String($0.id),"type":($0 as? Entity)?.type ?? "EntityRef"] }
                    let cell=game.world.getBlock(Int(lastX.rounded(.down)),Int((lastY+0.2).rounded(.down)),Int(lastZ.rounded(.down))) >> 4
                    let ground=game.world.getBlock(Int(lastX.rounded(.down)),Int((lastY-0.1).rounded(.down)),Int(lastZ.rounded(.down))) >> 4
                    let slow=[Int(B.cobweb),Int(B.sweet_berry_bush),Int(B.powder_snow),Int(B.honey_block)].contains(cell) || ground == Int(B.honey_block)
                    edgeRows.append(["from":["x":lastX,"y":lastY,"z":lastZ],"to":p(node.x,node.y,node.z),"placementValid":site.isValid,"placementRejections":site.rejections.map(\.rawValue),"requested":[dx,dy,dz],"coreSweep":[clippedX,clippedY,clippedZ],"sweepExact":dx==clippedX && dy==clippedY && dz==clippedZ,"sweptOccupants":occupants,"movementSlowCell":slow,"supportedExecutorStep":max(abs(dx),abs(dz))==1 && abs(dy)<=1])
                    lastX=Double(node.x)+0.5;lastY=Double(node.y);lastZ=Double(node.z)+0.5
                }
                row["edges"]=edgeRows
            case .noPath:row["coreResult"]="noPath"
            case .coverageLimited:row["coreResult"]="coverageLimited"
            case .coverageUnavailable:row["coreResult"]="coverageUnavailable"
            case .nodeBudgetExhausted:row["coreResult"]="nodeBudgetExhausted"
            }
            candidates.append(row)
        } } }
        let evidence:[String:Any] = ["worldTick":game.world.time,"civilizationTick":controller.session!.tick,"parentPhysical":["x":body.x,"y":body.y,"z":body.z,"entityID":Double(body.id)],"parent":try JSONSerialization.jsonObject(with:JSONEncoder().encode(parent)),"dependent":try JSONSerialization.jsonObject(with:JSONEncoder().encode(dependent)),"coverage":String(describing:game.world.physicalSimulationCoverage),"normalNavigationObservation":try JSONSerialization.jsonObject(with:JSONEncoder().encode(observation)),"freshNormalCoarsePlan":try JSONSerialization.jsonObject(with:JSONEncoder().encode(coarse)),"candidates":candidates,"geometry":geom,"allEntities":game.world.entities.map { ["id":$0.id,"type":($0 as? Entity)?.type ?? "EntityRef","body":boxes($0.bb())] as [String:Any] }]
        guard try controller.session!.durableStateBytes()==before,
              controller.probesByAgentId.mapValues({$0.capturePhysicalState()})==physicalBefore,
              game.world.time==timeBefore,
              try JSONSerialization.data(withJSONObject:geometry(),options:[.sortedKeys])==geomBefore else { throw Failure.refused("read-only route probe mutated truth") }
        try JSONSerialization.data(withJSONObject:evidence,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:output),options:.atomic)
        print("[care-probe] World=\(game.world.time) civ=\(controller.session!.tick) candidates=\(candidates.count) read-only PASS")
    }

    private static func exactBodies(_ controller: PebbleAgentController, _ game: GameCore,
        _ require: (Bool, String) throws -> Void, printAssertion: Bool = true) throws {
        let expected = controller.session!.expectedActiveAgentIDs().map(\.rawValue).sorted()
        let actual = game.world.entities.compactMap { ($0 as? LabCoreAgentEntity)?.labAgentId }.sorted()
        let exact = actual == expected && controller.probesByAgentId.keys.sorted() == expected
        if printAssertion { try require(exact, "exact session registry World body bijection") }
        else if !exact { throw Failure.refused("body bijection during ordinary progression") }
    }

    private static func step(_ game: GameCore, _ controller: PebbleAgentController, id: String) throws {
        _ = game.frame(dtMs: TICK_MS)
        let deadline = Date(timeIntervalSinceNow: 60)
        while game.physicalSimulationCoverageRuntimeDiagnostics(for: game.world).totalGenerationJobsInFlight > 0 {
            guard Date() < deadline else { throw Failure.refused("generation timeout") }
            _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
        }
        controller.update(world: game.world, player: game.player, worldID: id, dimension: game.dim.rawValue)
        if let failure = controller.fatalSessionIntegrityFailure { throw Failure.refused(failure) }
    }

    private enum Failure: Error { case refused(String) }
}
