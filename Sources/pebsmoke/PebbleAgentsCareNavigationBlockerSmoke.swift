import Foundation
import PebbleAgents

func runPebbleAgentsCareNavigationBlockerSmoke() {
    section("PS01 care navigation prospective proposal and bounded recovery")
    let origin = AgentPosition(x: 0, y: 64, z: 0)
    let target = AgentPosition(x: 2, y: 64, z: 0)
    func world(tick: Int = 1, ready: Bool = true, clear: Bool = true,
               step: Int? = 0, version: Int? = 1, metadata: Int = 0) -> AgentWorldObservation {
        func column(_ p: AgentPosition) -> AgentWorldColumnObservation {
            AgentWorldColumnObservation(position: p, chunkReady: ready,
                surfaceY: ready ? 64 : nil, height: ready ? 63 : nil,
                blockBelow: ready ? 1 : nil, blockAtFeet: ready ? metadata : nil,
                blockAtHead: ready ? 0 : nil, groundPresent: ready,
                feetClear: clear && ready, headClear: ready)
        }
        return try! AgentWorldObservation(worldTick: tick, position: origin, center: column(origin),
            neighbors: AgentCardinalDirection.allCases.map { d in
                AgentWorldNeighborObservation(direction: d,
                    column: column(AgentPosition(x: d.dx, y: 64, z: d.dz)),
                    stepDelta: step, traversable: ready && clear && step == 0,
                    dangerousDrop: (step ?? 0) < -1)
            }, biomeId: 1, biomeName: "plains", combinedLight: 15, skyLight: 15,
            blockLight: 0, dayTime: tick, raining: false, thundering: false,
            physicalCoverageDigest: "ready", physicalMovementAssessmentVersion: version)
    }
    func nav(tick: Int = 1, blocked: Bool = false, reverse: Bool = false) -> AgentNavigationObservation {
        var cells = [AgentNavigationCell(position: origin, status: .traversable),
            AgentNavigationCell(position: AgentPosition(x: 1, y: 64, z: 0), status: blocked ? .blocked : .traversable),
            AgentNavigationCell(position: target, status: .blocked)]
        if reverse { cells.reverse() }
        return AgentNavigationObservation(worldTick: tick, origin: origin, target: target, cells: cells)
    }
    let first = AgentCareNavigationProposal.observe(navigation: nav(), world: world(), previous: nil)
    check("care viable proposal is bounded and prevalidated",first.plan?.found == true && first.observation.intentDigest != nil)
    var stable = first.observation
    var extraPlans = 0
    for tick in 2...100 {
        let result = AgentCareNavigationProposal.observe(navigation: nav(tick: tick), world: world(tick: tick), previous: stable)
        if result.plan != nil { extraPlans += 1 }
        stable = result.observation
    }
    check("unchanged opportunity creates no per-tick planning or new intent",extraPlans == 0 && stable == first.observation)
    let reordered = AgentCareNavigationProposal.observe(navigation: nav(reverse: true), world: world(), previous: nil)
    check("proposal ordering is deterministic",reordered.observation == first.observation)
    let irrelevant = AgentCareNavigationProposal.observe(navigation: nav(), world: world(metadata: 7), previous: first.observation)
    check("changed irrelevant metadata cannot replenish same intent",irrelevant.observation.contextDigest != first.observation.contextDigest && irrelevant.observation.intentDigest == first.observation.intentDigest)
    for (name, obs) in [("legacy",world(version:nil)),("unknown version",world(version:99)),
                         ("unavailable",world(ready:false)),("body blocked",world(clear:false)),
                         ("illegal drop",world(step:-3)),("wrong step",world(step:1))] {
        let r = AgentCareNavigationProposal.observe(navigation: nav(), world: obs, previous:nil)
        check("care inadmissible input has no recovery identity: " + name,r.observation.intentDigest == nil)
    }
    let absent = AgentCareNavigationProposal.observe(navigation: nav(blocked:true), world: world(), previous:nil)
    check("actually unreachable coarse target creates no intent",absent.plan?.found == false && absent.observation.intentDigest == nil)
    let recovered = AgentCareNavigationProposal.observe(navigation: nav(), world: world(), previous:absent.observation)
    check("changed valid opportunity after failure creates new admissible intent",recovered.observation.intentDigest != nil && recovered.observation.intentDigest != absent.observation.intentDigest)
    let diagonalTarget = AgentPosition(x:2,y:64,z:1)
    let diagonal = AgentNavigationObservation(worldTick:1,origin:origin,target:diagonalTarget,cells:[
        AgentNavigationCell(position:origin,status:.traversable),
        AgentNavigationCell(position:AgentPosition(x:1,y:64,z:0),status:.traversable),
        AgentNavigationCell(position:diagonalTarget,status:.blocked)])
    let cardinalOnly = AgentCareNavigationProposal.observe(navigation:diagonal,world:world(),previous:nil)
    let diagonalCare = AgentCareNavigationProposal.observe(navigation:diagonal,world:world(),
        goalMode:.chebyshevAdjacent,previous:nil)
    check("cardinal-only goals cannot invent a missing cardinal site", cardinalOnly.plan?.found == false)
    check("care goal finds legal diagonal interaction using cardinal movement", diagonalCare.plan?.positions ==
        [origin,AgentPosition(x:1,y:64,z:0)] && diagonalCare.observation.intentDigest != nil)
    let stale = AgentCareNavigationProposal.observe(navigation: nav(tick:2), world:world(), previous:nil)
    check("stale physical observation cannot certify recovery",stale.observation.intentDigest == nil)
    let exhausted = AgentNavigationProgress(status: .failed, replanCount: 3,
        lastPlanTick: 10, lastFailure: .replanLimitReached)
    check("new admitted intent waits for existing cooldown", !first.observation.refreshesExhaustedBudget(
        progress: exhausted, tick: 10, maximumReplans: 3, cooldown: 4))
    check("pending admitted intent recovers after cooldown", first.observation.refreshesExhaustedBudget(
        progress: exhausted, tick: 14, maximumReplans: 3, cooldown: 4))
    let attempted = first.observation.recordingAttempt()
    check("same attempted intent never refills exhausted budget", !attempted.refreshesExhaustedBudget(
        progress: exhausted, tick: 100, maximumReplans: 3, cooldown: 4))
    let interrupted = AgentCareNavigationProposal.observe(navigation: nav(blocked:true), world:world(), previous:attempted)
    let repeatIntent = AgentCareNavigationProposal.observe(navigation:nav(),world:world(),previous:interrupted.observation)
    check("blocked then clear does not erase prior attempt", !repeatIntent.observation.refreshesExhaustedBudget(
        progress: exhausted, tick:100, maximumReplans:3, cooldown:4))
    let unavailableGap = AgentCareNavigationProposal.observe(navigation:nav(),world:world(ready:false),previous:attempted)
    let readyAgain = AgentCareNavigationProposal.observe(navigation:nav(),world:world(),previous:unavailableGap.observation)
    check("unavailable then ready cannot erase an exhausted intent", !readyAgain.observation.refreshesExhaustedBudget(
        progress:exhausted,tick:1000,maximumReplans:3,cooldown:4))
    let detour = AgentNavigationObservation(worldTick:1,origin:origin,target:target,cells:[
        AgentNavigationCell(position:origin,status:.traversable),
        AgentNavigationCell(position:AgentPosition(x:0,y:64,z:-1),status:.traversable),
        AgentNavigationCell(position:AgentPosition(x:1,y:64,z:-1),status:.traversable),
        AgentNavigationCell(position:AgentPosition(x:2,y:64,z:-1),status:.traversable),
        AgentNavigationCell(position:target,status:.blocked)])
    let changedRoute = AgentCareNavigationProposal.observe(navigation:detour,world:world(),previous:attempted)
    check("different admissible route receives one new bounded episode", changedRoute.observation.refreshesExhaustedBudget(
        progress:exhausted,tick:100,maximumReplans:3,cooldown:4))
    check("recovered route cannot refill again after exhaustion", !changedRoute.observation.recordingAttempt().refreshesExhaustedBudget(
        progress:exhausted,tick:1000,maximumReplans:3,cooldown:4))
    let routeCycle = AgentCareNavigationProposal.observe(navigation:nav(),world:world(),
        previous:changedRoute.observation.recordingAttempt())
    check("A/B/A route churn cannot repeat an attempted failed intent", !routeCycle.observation.refreshesExhaustedBudget(
        progress:exhausted,tick:1000,maximumReplans:3,cooldown:4))
    let staleCached = AgentCareNavigationProposal.observe(navigation:nav(tick:2),world:world(),previous:attempted)
    check("cached admission cannot bypass freshness", staleCached.observation.intentDigest == nil)
    do {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let bytes = try encoder.encode(first.observation)
        check("proposal memory roundtrips exactly",try JSONDecoder().decode(AgentCareNavigationProposal.self,from:bytes) == first.observation)
        let restoredAttempt = try JSONDecoder().decode(AgentCareNavigationProposal.self,from:encoder.encode(attempted))
        check("restart retains exhausted intent refusal", !restoredAttempt.refreshesExhaustedBudget(
            progress:exhausted,tick:100,maximumReplans:3,cooldown:4))
        var cappedObject = try JSONSerialization.jsonObject(with:encoder.encode(first.observation)) as! [String:Any]
        cappedObject["attemptedIntentDigests"] = ["1","2","3","4"]
        let capped = try JSONDecoder().decode(AgentCareNavigationProposal.self,from:
            JSONSerialization.data(withJSONObject:cappedObject,options:[.sortedKeys]))
        check("distinct recovery episodes have a fixed ceiling", !capped.refreshesExhaustedBudget(
            progress:exhausted,tick:1000,maximumReplans:3,cooldown:4))
        cappedObject["attemptedIntentDigests"] = ["1","2","3","4","5"]
        check("codec rejects unbounded attempt history", (try? JSONDecoder().decode(AgentCareNavigationProposal.self,from:
            JSONSerialization.data(withJSONObject:cappedObject))) == nil)
        let invalid = Data("{\"version\":99,\"contextDigest\":\"z\"}".utf8)
        check("proposal rejects unsupported or unbounded memory", (try? JSONDecoder().decode(AgentCareNavigationProposal.self,from:invalid)) == nil)
        let historical = world(version:nil)
        let data = try encoder.encode(historical)
        let object = try JSONSerialization.jsonObject(with:data) as! [String:Any]
        check("historical observation omits new fields",object["physicalMovementAssessmentVersion"] == nil && object["careNavigationProposal"] == nil)
        let restored = try JSONDecoder().decode(AgentWorldObservation.self,from:data)
        check("historical observation bytes remain identical",try encoder.encode(restored) == data)
    } catch { check("care proposal codec",false) }
}
