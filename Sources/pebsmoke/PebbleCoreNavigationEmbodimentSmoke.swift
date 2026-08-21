import PebbleCore

private func civ19NavigationWorld(seed: UInt32 = 19) -> World {
    let world = World(dim: .overworld, seed: seed)
    for cz in -1...1 {
        for cx in -1...1 {
            let chunk = Chunk(
                cx: cx,
                cz: cz,
                minY: world.info.minY,
                height: world.info.height
            )
            chunk.buildHeightmap()
            chunk.status = .lit
            world.setChunk(chunk)
        }
    }
    for z in -12...12 {
        for x in -12...12 {
            world.setBlock(x, 63, z, Int(cell(B.stone)), SET_SILENT)
        }
    }
    return world
}

private func civ19NodeDigest(_ path: [PathNode]?) -> String {
    path?.map { "\($0.x),\($0.y),\($0.z)" }.joined(separator: ";") ?? "nil"
}

func runPebbleCoreNavigationEmbodimentSmoke() {
    section("CIV-19 PebbleCore physical navigation authority")

    let simple = civ19NavigationWorld()
    let first = findPath(simple, 0.5, 64, 0.5, 4.5, 64, 0.5, 600, true)
    let second = findPath(simple, 0.5, 64, 0.5, 4.5, 64, 0.5, 600, true)
    check("CIV-19 Core simple route exists", first?.isEmpty == false)
    check("CIV-19 Core route is deterministic",
          civ19NodeDigest(first) == civ19NodeDigest(second))

    let probe = LabCoreAgentEntity(
        world: simple,
        labAgentId: "civ19_probe",
        physicalId: "civ19_probe"
    )
    probe.setPos(0.5, 64, 0.5) // fixture spawn only
    simple.addEntity(probe)
    if let node = first?.first {
        probe.move(
            Double(node.x) + 0.5 - probe.x,
            Double(node.y) - probe.y,
            Double(node.z) + 0.5 - probe.z
        )
        check("CIV-19 Entity.move reaches Core-selected node",
              Int(probe.x.rounded(.down)) == node.x
                  && Int(probe.y.rounded(.down)) == node.y
                  && Int(probe.z.rounded(.down)) == node.z)
    } else {
        check("CIV-19 Entity.move reaches Core-selected node", false)
    }

    let obstacle = civ19NavigationWorld()
    obstacle.setBlock(1, 64, 0, Int(cell(B.stone)), SET_SILENT)
    obstacle.setBlock(1, 65, 0, Int(cell(B.stone)), SET_SILENT)
    let around = findPath(obstacle, 0.5, 64, 0.5, 4.5, 64, 0.5, 600, true)
    check("CIV-19 Core routes around static obstacle",
          around?.contains(where: { $0.x == 1 && $0.y == 64 && $0.z == 0 }) == false
              && around?.isEmpty == false)

    let dynamic = civ19NavigationWorld()
    let beforeChange = findPath(dynamic, 0.5, 64, 0.5, 4.5, 64, 0.5, 600, true)
    if let blockedNode = beforeChange?.first {
        dynamic.setBlock(blockedNode.x, blockedNode.y, blockedNode.z,
                         Int(cell(B.stone)), SET_SILENT)
        dynamic.setBlock(blockedNode.x, blockedNode.y + 1, blockedNode.z,
                         Int(cell(B.stone)), SET_SILENT)
        let afterChange = findPath(dynamic, 0.5, 64, 0.5, 4.5, 64, 0.5, 600, true)
        check("CIV-19 dynamic World change forces Core replan",
              afterChange?.first.map {
                  $0.x != blockedNode.x || $0.y != blockedNode.y || $0.z != blockedNode.z
              } == true)
    } else {
        check("CIV-19 dynamic World change forces Core replan", false)
    }

    let step = civ19NavigationWorld()
    step.setBlock(1, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let upward = findPath(step, 0.5, 64, 0.5, 1.5, 65, 0.5, 600, true)
    check("CIV-19 Core selects legal vertical step",
          upward?.first.map { $0.x == 1 && $0.y == 65 && $0.z == 0 } == true)
    let stepProbe = LabCoreAgentEntity(
        world: step,
        labAgentId: "civ19_step_probe",
        physicalId: "civ19_step_probe"
    )
    stepProbe.setPos(0.5, 64, 0.5) // fixture spawn only
    step.addEntity(stepProbe)
    if let node = upward?.first {
        stepProbe.move(
            Double(node.x) + 0.5 - stepProbe.x,
            Double(node.y) - stepProbe.y,
            Double(node.z) + 0.5 - stepProbe.z
        )
    }
    check("CIV-19 Core collision permits verified vertical step",
          Int(stepProbe.x.rounded(.down)) == 1
              && Int(stepProbe.y.rounded(.down)) == 65)

    let descent = civ19NavigationWorld()
    descent.setBlock(0, 64, 0, Int(cell(B.stone)), SET_SILENT)
    let descentProbe = LabCoreAgentEntity(
        world: descent,
        labAgentId: "civ39_descent_probe",
        physicalId: "civ39_descent_probe"
    )
    descentProbe.setPos(0.5, 65, 0.5) // fixture spawn only
    descent.addEntity(descentProbe)
    descentProbe.move(1, 0, 0)
    descentProbe.move(0, -1, 0)
    check("CIV-39 Core descent sequence leaves support before settling",
          Int(descentProbe.x.rounded(.down)) == 1
              && Int(descentProbe.y.rounded(.down)) == 64
              && Int(descentProbe.z.rounded(.down)) == 0)

    let gap = civ19NavigationWorld()
    gap.setBlock(1, 63, 0, 0, SET_SILENT)
    let gapRoute = findPath(gap, 0.5, 64, 0.5, 2.5, 64, 0.5, 600, true)
    check("CIV-19 Core never selects unsupported gap cell",
          gapRoute?.contains(where: { $0.x == 1 && $0.y == 64 && $0.z == 0 }) != true)
}
