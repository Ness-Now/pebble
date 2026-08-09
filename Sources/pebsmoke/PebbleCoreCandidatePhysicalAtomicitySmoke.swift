import PebbleCore

func runPebbleCoreCandidatePhysicalAtomicitySmoke() {
    section("Gate D Blocker 04 candidate physical atomicity")

    let world = World(dim: .overworld, seed: 404)
    let chunk = Chunk(
        cx: 0, cz: 0, minY: world.info.minY, height: world.info.height
    )
    chunk.buildHeightmap()
    chunk.status = .lit
    world.setChunk(chunk)
    for z in 0...3 {
        for x in 0...3 {
            world.setBlock(x, 63, z, Int(cell(B.stone)), SET_SILENT)
        }
    }

    let probe = LabCoreAgentEntity(
        world: world,
        labAgentId: "candidate_atomicity",
        physicalId: "candidate_atomicity"
    )
    probe.setPos(0.5, 64, 0.5)
    probe.prevX = -0.25
    probe.prevY = 63.75
    probe.prevZ = 0.25
    probe.vx = 0.125
    probe.vy = -0.25
    probe.vz = 0.375
    probe.yaw = 0.75
    probe.pitch = -0.25
    probe.prevYaw = 0.5
    probe.prevPitch = -0.125
    probe.onGround = false
    probe.horizontalCollision = true
    probe.fallDistance = 2.5
    world.addEntity(probe)

    let published = probe.capturePhysicalState()
    probe.move(1, 0, 0)
    probe.vx = -9
    probe.vy = 8
    probe.vz = -7
    probe.onGround.toggle()
    probe.horizontalCollision.toggle()
    probe.fallDistance = 99
    check(
        "candidateTickFailureAfterVerifiedMovementRestoresAllPhysicalState mutates",
        probe.capturePhysicalState() != published
    )
    check(
        "candidateTickFailureAfterVerifiedMovementRestoresAllPhysicalState restores",
        probe.restorePhysicalState(published)
            && probe.capturePhysicalState() == published
    )

    let worldTickBeforeExternalProgression = world.time
    world.tick()
    let acquiredWorldTick = world.time
    let candidateBefore = probe.capturePhysicalState()
    probe.move(1, 0, 0)
    check(
        "renewableWorldAdvanceRemainsExternalAfterCandidateFailure",
        acquiredWorldTick > worldTickBeforeExternalProgression
            && probe.restorePhysicalState(candidateBefore)
            && world.time == acquiredWorldTick
    )
}
