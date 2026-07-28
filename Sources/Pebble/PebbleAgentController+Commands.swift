import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleCommand(_ arguments: [String], world: World, player: Player) -> PebbleAgentCommandResult {
        let command = arguments.first?.lowercased() ?? "status"
        if passiveObserverBootstrapComplete {
            let productive = isManualProductiveCommand(arguments)
            if productive { manualProductiveCommandsAfterBootstrap += 1 }
            trace(
                "passive command command=/lab_\(arguments.joined(separator: "_")) "
                    + "class=\(productive ? "productive" : "observer_debug") "
                    + "productiveCount=\(manualProductiveCommandsAfterBootstrap)"
            )
        }
        switch command {
        case "help":
            guard arguments.count == 1 else { return failure("Usage: /lab help") }
            return success("/lab session: start stop clear | lifecycle <on|status|clear> reproduction <on|off|status> births status kinship <on|status> household <on|status> care <on|status> | time control: pause resume step speed <1|2|4|8> reset | inspection: status focus <agentId|next> next follow <agentId|focus|next|off> overlay <off|compact|full> causality <status|tail <1...20>> scale status | persistence: checkpoint <status|list|save|load|delete> replay <status|start|stop|verify> | movement: movement <on|off> embodiment proof | interaction: interaction <setup|setup distant <2...8>|harvest|status|auto on|auto off> gateway proof material proof harvest proof construction proof | economy: economy <setup|auto on|auto off|status|clear> | survival: survival <on|off|status> | natural: natural <on|off|status|scan> | ecology: ecology <on|off|status|scan|clear> forage status | ecological-observation <on|status|scan|proof> agriculture <on|status|proof> wild-subsistence <on|status|proof [setup|fish|hunt|gather|final]> work-professions <on|refresh|match|record|crisis|resume|status|final> | mortality: mortality <on|off|status|clear> exits status | build: build <setup|auto on|auto off|status|clear> | social: social <on|off|status|clear> | physical: physical <on|off|status|clear> | cooperation: cooperation <on|off|status|clear> | population: population <on|off|status|clear> migration <admit|status> | settlement: settlement <on|off|status|clear> | demo: demo [start|stop|status]")
        case "demo":
            return handleDemo(Array(arguments.dropFirst()), world: world, player: player)
        case "autonomous-civilization":
            return handleAutonomousCivilization(
                Array(arguments.dropFirst()), world: world, player: player
            )
        case "start":
            guard arguments.count == 1 else { return failure("Usage: /lab start") }
            return start(world: world, player: player)
        case "stop", "clear":
            guard arguments.count == 1 else { return failure("Usage: /lab \(command)") }
            let removed = stop(reason: command, fallbackWorld: world)
            guard session == nil else {
                return failure(lastError ?? "PebbleAgents stop refused: verified cleanup failed.")
            }
            return success("PebbleAgents stopped; probes removed: \(removed)")
        case "pause":
            guard arguments.count == 1 else { return failure("Usage: /lab pause") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            isPaused = true
            lastWorldTick = world.time
            credit = 0
            trace("pause tick=\(session?.tick ?? 0)")
            return success("PebbleAgents paused at tick \(session?.tick ?? 0).")
        case "resume":
            guard arguments.count == 1 else { return failure("Usage: /lab resume") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            isPaused = false
            lastWorldTick = world.time
            credit = 0
            trace("resume tick=\(session?.tick ?? 0)")
            return success("PebbleAgents resumed at \(cognitiveHz) Hz.")
        case "step":
            guard arguments.count == 1 else { return failure("Usage: /lab step") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard advanceOneTick(world: world, player: player) else { return failure(lastError ?? "Cognitive step failed.") }
            trace("step tick=\(session?.tick ?? 0)")
            return success("PebbleAgents stepped to tick \(session?.tick ?? 0).")
        case "speed":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2, let hz = Int(arguments[1]), [1, 2, 4, 8].contains(hz) else {
                return failure("Usage: /lab speed <1|2|4|8>")
            }
            cognitiveHz = hz
            credit = 0
            return success("PebbleAgents speed set to \(hz) Hz.")
        case "reset":
            guard arguments.count == 1 else { return failure("Usage: /lab reset") }
            guard session != nil, activeWorld === world, let anchor else {
                return failure("No active PebbleAgents session.")
            }
            return rebuild(
                world: world,
                player: player,
                anchor: anchor,
                seed: seed,
                resetSpeed: false
            )
        case "movement":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2, arguments[1] == "on" || arguments[1] == "off" else {
                return failure("Usage: /lab movement <on|off>")
            }
            if arguments[1] == "on" {
                guard movementFeatureEnabled else {
                    return failure("PebbleAgents movement disabled. Set PEBBLELAB_APP_AGENTS_MOVE=1 before launch.")
                }
                movementEnabled = true
                movementWasEverEnabledSinceReset = true
            } else {
                movementEnabled = false
            }
            let movementStatus = movementEnabled ? "on" : "off"
            trace("movement=\(movementStatus) tick=\(session?.tick ?? 0)")
            return success("PebbleAgents movement \(movementStatus).")
        case "embodiment":
            return handleEmbodimentConvergence(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "interaction":
            return handleInteraction(Array(arguments.dropFirst()), world: world, player: player)
        case "gateway":
            return handlePhysicalActionGateway(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "material":
            return handleMaterialCustody(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "harvest":
            return handleHarvestConvergence(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "construction":
            return handleConstructionConvergence(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "economy":
            return handleEconomy(Array(arguments.dropFirst()), world: world, player: player)
        case "survival":
            return handleSurvival(Array(arguments.dropFirst()))
        case "physical-food-survival":
            return handlePhysicalFoodSurvival(
                Array(arguments.dropFirst()), world: world
            )
        case "natural":
            return handleNatural(Array(arguments.dropFirst()), world: world, player: player)
        case "ecology":
            return handleEcology(Array(arguments.dropFirst()), world: world, player: player)
        case "ecological-observation":
            return handleEcologicalObservation(
                Array(arguments.dropFirst()), world: world, player: player
            )
        case "agriculture":
            return handleAgriculture(
                Array(arguments.dropFirst()), world: world, player: player
            )
        case "wild-subsistence":
            return handleWildSubsistence(
                Array(arguments.dropFirst()), world: world, player: player
            )
        case "livestock":
            return handleLivestock(
                Array(arguments.dropFirst()), world: world, player: player
            )
        case "work-professions":
            return handleWorkProfessions(Array(arguments.dropFirst()), world: world)
        case "forage":
            return handleForage(Array(arguments.dropFirst()))
        case "mortality":
            return handleMortality(Array(arguments.dropFirst()))
        case "exits":
            return handlePopulationExits(Array(arguments.dropFirst()))
        case "lifecycle":
            return handleLifecycleAge(Array(arguments.dropFirst()))
        case "reproduction":
            return handleReproduction(Array(arguments.dropFirst()))
        case "births":
            return handleBirths(Array(arguments.dropFirst()))
        case "kinship":
            return handleKinship(Array(arguments.dropFirst()))
        case "household":
            return handleHousehold(Array(arguments.dropFirst()))
        case "care":
            return handleDependentCare(Array(arguments.dropFirst()), world: world)
        case "skills":
            return handleSkills(Array(arguments.dropFirst()))
        case "teaching":
            return handleTeaching(
                Array(arguments.dropFirst()), world: world, player: player
            )
        case "build":
            return handleBuild(Array(arguments.dropFirst()), world: world, player: player)
        case "causality":
            return handleCausality(Array(arguments.dropFirst()))
        case "checkpoint":
            return handleCheckpoint(Array(arguments.dropFirst()), world: world)
        case "replay":
            return handleReplay(Array(arguments.dropFirst()))
        case "social":
            return handleSocial(Array(arguments.dropFirst()))
        case "physical":
            return handlePhysical(Array(arguments.dropFirst()))
        case "cooperation":
            return handleCooperation(Array(arguments.dropFirst()))
        case "population":
            return handlePopulation(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "migration":
            return handleMigration(
                Array(arguments.dropFirst()),
                world: world,
                player: player
            )
        case "settlement":
            return handleSettlementMetrics(Array(arguments.dropFirst()))
        case "scale":
            return handleScaleStatus(Array(arguments.dropFirst()))
        case "status":
            guard arguments.count == 1 else { return failure("Usage: /lab status") }
            guard let session else {
                trace("status inactive gate=\(featureEnabled ? "enabled" : "disabled")")
                return success("PebbleAgents inactive (gate \(featureEnabled ? "enabled" : "disabled")).")
            }
            let snapshot = session.snapshot()
            let positions = snapshot.agents.map { "\($0.id)=\($0.position.x),\($0.position.y),\($0.position.z)/m\($0.movementCount)/o\($0.observationCount)" }.joined(separator: " ")
            let overlay = effectiveOverlayMode(f3Visible: false).rawValue
            let socialStatus = session.socialEnabled ? " social=on" : ""
            let physicalStatus = session.physicalEnabled ? " physical=on" : ""
            let cooperationStatus = session.cooperationEnabled ? " cooperation=on" : ""
            let populationStatus = session.populationEnabled ? " population=on" : ""
            let settlementStatus = session.settlementMetricsEnabled ? " settlement=on" : ""
            let ecologyStatus = session.localEcologyEnabled ? " ecology=on" : ""
            let mortalityStatus = session.mortalityEnabled ? " mortality=on" : ""
            let lifecycleStatus = session.lifecycleEnabled ? " lifecycle=on" : ""
            let kinshipStatus = session.kinshipEnabled ? " kinship=on" : ""
            let householdStatus = session.householdsEnabled ? " households=on" : ""
            let careStatus = session.dependentCareEnabled ? " care=on" : ""
            let skillStatus = session.skillsEnabled ? " skills=on" : ""
            let teachingStatus = session.teachingEnabled ? " teaching=on" : ""
            let message = "PebbleAgents \(isPaused ? "paused" : "running") tick=\(snapshot.tick) hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off") autoInteraction=\(autoInteractionEnabled ? "on" : "off") economy=\(snapshot.economyEnabled ? "on" : "off") survival=\(snapshot.survivalEnabled ? "on" : "off") natural=\(snapshot.naturalResourcesEnabled ? "on" : "off") build=\(snapshot.buildAutoEnabled ? "on" : "off")\(socialStatus)\(physicalStatus)\(cooperationStatus)\(populationStatus)\(settlementStatus)\(ecologyStatus)\(mortalityStatus)\(lifecycleStatus)\(kinshipStatus)\(householdStatus)\(careStatus)\(skillStatus)\(teachingStatus) probes=\(probesByAgentId.count) focus=\(focusedAgentId ?? "none") follow=\(followMode.statusText) overlay=\(overlay) demo=\(demoActive ? "on" : "off") catchupDropped=\(droppedCatchUpSteps) \(positions)"
            trace("status \(message)")
            return success(message)
        case "focus":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2 else { return failure("Usage: /lab focus <agentId|next>") }
            return setFocus(arguments[1])
        case "next":
            guard arguments.count == 1 else { return failure("Usage: /lab next") }
            guard session != nil else { return failure("No active PebbleAgents session.") }
            return setFocus("next")
        case "follow":
            guard session != nil else { return failure("No active PebbleAgents session.") }
            guard arguments.count == 2 else { return failure("Usage: /lab follow <agentId|focus|next|off>") }
            let requested = arguments[1]
            switch requested.lowercased() {
            case "off":
                followMode = .off
            case "focus":
                followMode = .focusedAgent
            case "next":
                let result = setFocus("next")
                guard result.succeeded else { return result }
                followMode = .focusedAgent
            default:
                guard probesByAgentId[requested] != nil else { return failure("Unknown agent id: \(requested)") }
                followMode = .fixedAgent(requested)
            }
            trace("follow=\(followMode.statusText) tick=\(session?.tick ?? 0)")
            applyFollow(player: player)
            return success("PebbleAgents follow: \(followMode.statusText).")
        case "overlay":
            guard arguments.count == 2 else {
                return failure("Usage: /lab overlay <off|compact|full>")
            }
            let requested = arguments[1].lowercased()
            switch requested {
            case "off": overlayModeByCommand = .off
            case "on", "compact": overlayModeByCommand = .compact
            case "full": overlayModeByCommand = .full
            default: return failure("Usage: /lab overlay <off|compact|full>")
            }
            return success("PebbleAgents overlay \(overlayModeByCommand!.rawValue).")
        default:
            return failure("Unknown /lab command. Use /lab help.")
        }
    }

    private func isManualProductiveCommand(_ arguments: [String]) -> Bool {
        guard let command = arguments.first?.lowercased() else { return false }
        let productiveDomains: Set<String> = [
            "interaction", "gateway", "material", "harvest", "construction",
            "economy", "natural", "ecology", "ecological-observation",
            "agriculture", "wild-subsistence", "livestock", "work-professions",
            "forage", "care", "teaching", "build",
        ]
        guard productiveDomains.contains(command) else { return false }
        let inspectionOrGate = arguments.dropFirst().first?.lowercased()
        return inspectionOrGate != "status" && inspectionOrGate != "on"
            && inspectionOrGate != "off"
    }

    @discardableResult
    func setFocus(_ requested: String) -> PebbleAgentCommandResult {
        guard let session else { return failure("No active PebbleAgents session.") }
        let ids = session.snapshot().agents.map(\.id)
        guard !ids.isEmpty else {
            focusedAgentId = nil
            followMode = .off
            return failure("No active agent to focus.")
        }
        let next: String
        if requested.lowercased() == "next" {
            let index = ids.firstIndex(of: focusedAgentId ?? "") ?? -1
            next = ids[(index + 1) % ids.count]
        } else {
            guard ids.contains(requested) else { return failure("Unknown agent id: \(requested)") }
            next = requested
        }
        focusedAgentId = next
        return success("PebbleAgents focus: \(next).")
    }

    func handleDemo(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let subcommand = arguments.first?.lowercased() ?? "start"
        guard arguments.count <= 1 else { return failure("Usage: /lab demo [start|stop|status]") }
        switch subcommand {
        case "start":
            let gates = [
                ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
                ("PEBBLELAB_APP_AGENTS_MOVE=1", movementFeatureEnabled),
                ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
                ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ]
            let missing = gates.filter { !$0.1 }.map(\.0)
            guard missing.isEmpty else {
                return failure("PebbleAgents demo refused; missing gates: \(missing.joined(separator: ", "))")
            }
            if session != nil || activeWorld != nil {
                _ = stop(reason: "demo restart", fallbackWorld: world)
            }
            let result = start(world: world, player: player)
            guard result.succeeded else { return result }
            cognitiveHz = 4
            isPaused = false
            movementEnabled = true
            movementWasEverEnabledSinceReset = true
            focusedAgentId = "agent_2"
            followMode = .focusedAgent
            overlayModeByCommand = .compact
            demoActive = true
            credit = 0
            lastWorldTick = world.time
            applyFollow(player: player)
            trace("demo start agents=3 hz=4 movement=on focus=agent_2 follow=focus overlay=compact")
            return success("PebbleAgents demo active: 3 agents, 4 Hz, movement on, focus agent_2, follow focus, overlay compact.")
        case "stop":
            let removed = stop(reason: "demo stop", fallbackWorld: world)
            guard session == nil else {
                return failure(lastError ?? "PebbleAgents demo stop refused: verified cleanup failed.")
            }
            trace("demo stop probesRemoved=\(removed)")
            return success("PebbleAgents demo stopped; probes removed: \(removed).")
        case "status":
            let active = session != nil
            return success("PebbleAgents demo \(demoActive && active ? "active" : "inactive") session=\(active ? "active" : "inactive") agents=\(session?.snapshot().agentCount ?? 0) hz=\(cognitiveHz) movement=\(movementEnabled ? "on" : "off") focus=\(focusedAgentId ?? "none") follow=\(followMode.statusText) overlay=\(effectiveOverlayMode(f3Visible: false).rawValue) probes=\(probesByAgentId.count).")
        default:
            return failure("Usage: /lab demo [start|stop|status]")
        }
    }

    func success(_ message: String) -> PebbleAgentCommandResult {
        PebbleAgentCommandResult(succeeded: true, message: message)
    }

    func failure(_ message: String) -> PebbleAgentCommandResult {
        lastError = message
        trace("error \(message)")
        return PebbleAgentCommandResult(succeeded: false, message: message)
    }

    func trace(_ message: String) {
        guard traceEnabled else { return }
        print("[lab-live] \(message)")
        fflush(stdout)
    }

    func traceTick(_ message: String, tick: Int, important: Bool) {
        guard important || tick % traceEvery == 0 else { return }
        trace(message)
    }

}
