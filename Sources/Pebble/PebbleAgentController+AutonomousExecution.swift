import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func executeAutonomousCivilizationActivity(
        actorIDText: String,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard let actorID = AgentID(rawValue: actorIDText),
              let activity = session.activeAutonomousActivity(for: actorID),
              let probe = probesByAgentId[actorIDText], probe.world === world, !probe.dead else {
            throw ControllerError.feedbackBoundary("autonomous activity lost embodiment")
        }
        let embodiment = PebbleAgentEmbodiment(probe: probe)
        let skillDomain = activity.candidate.domain.skillDomain
        let practiceBefore = skillDomain.map {
            session.practiceUnits(agentID: actorID, domain: $0)
        }
        let occupied = session.snapshot().agents.filter { $0.id != actorIDText }.map {
            PhysicalBlockPosition(x: $0.position.x, y: $0.position.y, z: $0.position.z)
        }
        do {
            let causalBefore = session.causalLedgerSnapshot().summary.latestSequence
            let receipt: String
            switch activity.candidate.domain {
            case .agriculture:
                receipt = try executeAutonomousAgriculture(
                    activity: activity, actor: embodiment, occupied: occupied,
                    world: world, session: &session, recorder: &recorder
                )
            case .wildGathering:
                receipt = try executeAutonomousGathering(
                    activity: activity, actor: embodiment, occupied: occupied,
                    world: world, session: &session, recorder: &recorder
                )
            case .livestock:
                receipt = try executeAutonomousLivestock(
                    activity: activity, actor: embodiment, world: world,
                    session: &session, recorder: &recorder
                )
            case .fishing:
                receipt = try executeAutonomousFishing(
                    activity: activity, actor: embodiment, world: world,
                    session: &session, recorder: &recorder
                )
            case .hunting:
                receipt = try executeAutonomousHunting(
                    activity: activity, actor: embodiment, world: world,
                    session: &session, recorder: &recorder
                )
            case .production:
                receipt = try executeAutonomousProduction(
                    activity: activity, actor: embodiment, world: world,
                    session: &session, recorder: &recorder
                )
            case .barter:
                receipt = try executeAutonomousBarter(
                    activity: activity, actor: embodiment, world: world,
                    session: &session, recorder: &recorder
                )
            case .contract:
                receipt = try executeAutonomousContract(
                    activity: activity, actor: embodiment, world: world,
                    session: &session, recorder: &recorder
                )
            case .dependentCare, .teaching, .construction, .materialHandling:
                throw ControllerError.feedbackBoundary(
                    "autonomous domain remains owned by its existing cognitive path"
                )
            }
            let newEvents = session.causalLedgerSnapshot().events.filter {
                $0.eventID.sequence.rawValue > causalBefore
            }
            let skillEvent = newEvents.first {
                $0.kind == .skillPracticeCredited && $0.actorID == actorID
            }
            let sourceEvent = skillEvent?.causes.first
                ?? newEvents.first(where: { $0.actorID == actorID })?.eventID
            if let sourceEvent {
                try recordAutonomousTeachingEvidenceIfEligible(
                    activity: activity, sourceSuccessEventID: sourceEvent,
                    skillPracticeEventID: skillEvent?.eventID,
                    world: world, session: &session, recorder: &recorder
                )
            }
            if let skillDomain, let practiceBefore {
                let practiceAfter = session.practiceUnits(
                    agentID: actorID, domain: skillDomain
                )
                trace(
                    "autonomous material practice actor=\(actorID.rawValue) "
                        + "domain=\(skillDomain.rawValue) "
                        + "source=\(sourceEvent?.rawValue ?? "none") "
                        + "skillEvent=\(skillEvent?.eventID.rawValue ?? "none") "
                        + "practice=\(practiceBefore)>\(practiceAfter) "
                        + "physicalReceipt=\(receipt) outputBonus=0 manualTrigger=0"
                )
            }
            let outcome = AgentAutonomousActivityOutcome(
                activityID: activity.activityID, actorID: actorID,
                lifecycle: .completed, completedAtTick: session.tick,
                physicalReceiptID: receipt, sourceEventID: sourceEvent,
                reason: "existing physical executor verified and published"
            )
            if try applyRecordedOperationIfActive(
                .autonomousActivityOutcome(outcome),
                session: &session, recorder: &recorder
            ) == nil {
                _ = try session.recordAutonomousActivityOutcome(outcome)
            }
            if session.workCommitmentsEnabled {
                _ = try recordAvailableLiveWorkEvidence(session: &session, recorder: &recorder)
            }
            recordPassiveSocietyCompletion(
                actorID: actorID,
                family: passiveActivityFamily(activity.candidate.domain),
                action: activity.candidate.actionKey,
                receipt: receipt,
                session: session
            )
            trace(
                "autonomous activity completed tick=\(session.tick) "
                    + "actor=\(actorIDText) "
                    + "domain=\(activity.candidate.domain.rawValue) "
                    + "action=\(activity.candidate.actionKey) receipt=\(receipt) "
                    + "manualTrigger=0"
            )
        } catch {
            if case ControllerError.barterPostMutationBoundary = error {
                throw error
            }
            if case ControllerError.contractPostMutationBoundary = error {
                throw error
            }
            let outcome = AgentAutonomousActivityOutcome(
                activityID: activity.activityID, actorID: actorID,
                lifecycle: .blocked, completedAtTick: session.tick,
                reason: String(describing: error)
            )
            if try applyRecordedOperationIfActive(
                .autonomousActivityOutcome(outcome),
                session: &session, recorder: &recorder
            ) == nil {
                _ = try session.recordAutonomousActivityOutcome(outcome)
            }
            trace(
                "autonomous activity blocked actor=\(actorIDText) "
                    + "domain=\(activity.candidate.domain.rawValue) "
                    + "reason=\(String(describing: error).replacingOccurrences(of: " ", with: "_"))"
            )
        }
    }

    private func executeAutonomousBarter(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let offerID = AgentBarterOfferID(
            rawValue: activity.candidate.stableReference
        ), let offer = session.barterSnapshot().offers.first(where: {
            $0.offerID == offerID && $0.status == .accepted
        }), offer.opportunity.offerorID.rawValue == actor.agentID,
              let counterpartyProbe = probesByAgentId[
                offer.opportunity.counterpartyID.rawValue
              ], counterpartyProbe.world === world, !counterpartyProbe.dead else {
            throw ControllerError.barterBoundary("accepted local offer unavailable")
        }
        let counterparty = PebbleAgentEmbodiment(probe: counterpartyProbe)
        let offerorEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            actor, in: world
        )
        let counterpartyEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            counterparty, in: world
        )
        let offeredDecision = session.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "barter:\(offerID.rawValue):offered",
            assetID: offer.opportunity.offered.assetID,
            actorID: offer.opportunity.offerorID,
            use: .transferCustody,
            verifiedHolder: offer.opportunity.offered.holderObservation
        ))
        let requestedDecision = session.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: "barter:\(offerID.rawValue):requested",
            assetID: offer.opportunity.requested.assetID,
            actorID: offer.opportunity.counterpartyID,
            use: .transferCustody,
            verifiedHolder: offer.opportunity.requested.holderObservation
        ))
        guard offeredDecision.verdict == .allowed,
              requestedDecision.verdict == .allowed else {
            try session.markBarterOfferFailed(
                offerID: offerID, status: .failed,
                reason: "rights refused offered=\(offeredDecision.reason.rawValue) requested=\(requestedDecision.reason.rawValue)"
            )
            throw ControllerError.barterBoundary("voluntary disposition refused")
        }
        let prevalidation = materialCustodyGateway.prevalidateBarter(
            PebbleAgentBarterPrevalidationRequest(
                transactionID: "barter:\(offerID.rawValue)",
                offered: offer.opportunity.offered.material,
                requested: offer.opportunity.requested.material,
                expectedOfferorFingerprint:
                    offer.opportunity.offered.holderObservation.custodyFingerprint,
                expectedCounterpartyFingerprint:
                    offer.opportunity.requested.holderObservation.custodyFingerprint
            ), offeror: offerorEndpoint, counterparty: counterpartyEndpoint
        )
        guard prevalidation == .succeeded else {
            try session.markBarterOfferFailed(
                offerID: offerID, status: .stale,
                reason: "physical prevalidation \(prevalidation.rawValue)"
            )
            throw ControllerError.barterBoundary(
                "physical prevalidation \(prevalidation.rawValue)"
            )
        }
        let firstReceipt = "barter:\(offerID.rawValue):offered"
        let first = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: firstReceipt,
                material: offer.opportunity.offered.material,
                expectedSourceFingerprint:
                    offer.opportunity.offered.holderObservation.custodyFingerprint,
                expectedDestinationFingerprint:
                    offer.opportunity.requested.holderObservation.custodyFingerprint
            ), from: offerorEndpoint, to: counterpartyEndpoint
        )
        guard first.succeeded,
              let offerorIntermediate = first.sourceFingerprint,
              let counterpartyIntermediate = first.destinationFingerprint else {
            throw ControllerError.barterBoundary(
                "first physical leg \(first.status.rawValue)"
            )
        }
        trace(
            "barter mid-exchange mutation offer=\(offerID.rawValue) "
                + "firstReceipt=\(firstReceipt) quantity=\(first.quantityMoved) "
                + "candidatePhysicalMutation=1 publication=0"
        )
        if environment["PEBBLELAB_DISPOSABLE_BARTER_MID_FAULT"] == "1",
           !barterMidExchangeFaultInjected {
            barterMidExchangeFaultInjected = true
            throw ControllerError.barterPostMutationBoundary(
                "injected after first real barter transfer"
            )
        }
        let secondReceipt = "barter:\(offerID.rawValue):requested"
        let second = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: secondReceipt,
                material: offer.opportunity.requested.material,
                expectedSourceFingerprint: counterpartyIntermediate,
                expectedDestinationFingerprint: offerorIntermediate
            ), from: counterpartyEndpoint, to: offerorEndpoint
        )
        guard second.succeeded,
              let counterpartyFinal = second.sourceFingerprint,
              let offerorFinal = second.destinationFingerprint else {
            throw ControllerError.barterPostMutationBoundary(
                "second physical leg \(second.status.rawValue)"
            )
        }
        let outcome = AgentVerifiedBarterOutcome(
            operationID: "barter:\(offerID.rawValue):completed",
            offerID: offerID,
            offeredLeg: AgentVerifiedBarterLeg(
                assetID: offer.opportunity.offered.assetID,
                sourceObservation: offer.opportunity.offered.holderObservation,
                destinationObservation: AgentMaterialHolderObservation(
                    holder: .agent(offer.opportunity.counterpartyID),
                    materialIdentity: offer.opportunity.offered.material.identity,
                    quantity: offer.opportunity.offered.material.count,
                    custodyFingerprint: counterpartyFinal,
                    physicalReceiptID: firstReceipt, observedAtTick: session.tick
                ), physicalReceiptID: firstReceipt
            ),
            requestedLeg: AgentVerifiedBarterLeg(
                assetID: offer.opportunity.requested.assetID,
                sourceObservation: offer.opportunity.requested.holderObservation,
                destinationObservation: AgentMaterialHolderObservation(
                    holder: .agent(offer.opportunity.offerorID),
                    materialIdentity: offer.opportunity.requested.material.identity,
                    quantity: offer.opportunity.requested.material.count,
                    custodyFingerprint: offerorFinal,
                    physicalReceiptID: secondReceipt, observedAtTick: session.tick
                ), physicalReceiptID: secondReceipt
            ), completedAtTick: session.tick
        )
        if try applyRecordedOperationIfActive(
            .recordVerifiedBarter(outcome),
            session: &session, recorder: &recorder
        ) == nil {
            try session.recordVerifiedBarter(outcome)
        }
        trace(
            "barter completed offer=\(offerID.rawValue) "
                + "offeror=\(offer.opportunity.offerorID.rawValue) "
                + "counterparty=\(offer.opportunity.counterpartyID.rawValue) "
                + "offered=\(offer.opportunity.offered.material.identity.itemKey):\(offer.opportunity.offered.material.count) "
                + "requested=\(offer.opportunity.requested.material.identity.itemKey):\(offer.opportunity.requested.material.count) "
                + "receipts=\(firstReceipt),\(secondReceipt) publication=verified"
        )
        return "barter:\(offerID.rawValue):completed"
    }

    private func executeAutonomousProduction(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let opportunityID = AgentProductionOpportunityID(
            rawValue: activity.candidate.stableReference
        ), let opportunity = session.productionSnapshot().opportunities.first(where: {
            $0.opportunityID == opportunityID
        }), opportunity.planFingerprint == activity.candidate.materialFingerprint else {
            throw ControllerError.feedbackBoundary("production opportunity stale")
        }
        let operationID = "produce:\(opportunity.opportunityID.rawValue)"
        guard productionInputsAreUnencumbered(opportunity, session: session) else {
            throw ControllerError.feedbackBoundary(
                "production input is reserved by Material Rights"
            )
        }
        let sessionBefore = session
        let recorderBefore = recorder
        var recorderCandidate = recorder
        let result = productionGateway.execute(
            PebbleAgentProductionRequest(
                operationID: operationID,
                opportunity: opportunity,
                completedAtTick: session.tick
            ),
            actor: actor,
            world: world,
            publish: { verified in
                if var activeRecorder = recorderCandidate {
                    _ = try activeRecorder.apply(
                        .recordVerifiedProduction(verified), to: &session
                    )
                    recorderCandidate = activeRecorder
                } else {
                    try session.recordVerifiedProduction(verified)
                }
                try registerContractPerformanceAssetIfNeeded(
                    verified, actor: actor, world: world,
                    session: &session, recorder: &recorderCandidate
                )
            }
        )
        guard result.succeeded else {
            session = sessionBefore
            recorder = recorderBefore
            throw ControllerError.feedbackBoundary(
                "production physical \(result.status.rawValue)"
            )
        }
        recorder = recorderCandidate
        trace(
            "production verified actor=\(opportunity.actorID.rawValue) "
                + "recipe=\(opportunity.recipeID) workshop="
                + "\(opportunity.workshopPosition.x),"
                + "\(opportunity.workshopPosition.y),"
                + "\(opportunity.workshopPosition.z) inputs="
                + opportunity.inputs.map {
                    "\($0.identity.itemKey):\($0.count)"
                }.joined(separator: ",")
                + " output=\(opportunity.output.identity.itemKey):"
                + "\(opportunity.output.count) receipt=\(operationID)"
        )
        return operationID
    }

    private func recordAutonomousTeachingEvidenceIfEligible(
        activity: AgentAutonomousActivity,
        sourceSuccessEventID: AgentCausalEventID,
        skillPracticeEventID: AgentCausalEventID?,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard session.teachingEnabled,
              let domain = activity.candidate.domain.skillDomain else { return }
        let actorID = activity.candidate.actorID
        let teaching = session.teachingSnapshot()
        for engagement in teaching.apprenticeships where
            engagement.status == .active && engagement.domain == domain {
            if engagement.teacherID == actorID,
               let teacher = try? PebbleAgentEmbodiment.resolve(
                   agentID: engagement.teacherID.rawValue,
                   in: world, mappedByAgentID: probesByAgentId
               ), let student = try? PebbleAgentEmbodiment.resolve(
                   agentID: engagement.studentID.rawValue,
                   in: world, mappedByAgentID: probesByAgentId
               ) {
                do {
                    let practiceBefore = session.practiceUnits(
                        agentID: engagement.studentID, domain: domain
                    )
                    let observation = try teachingObservationAdapter.observe(
                        world: world, teacher: teacher, student: student,
                        apprenticeshipID: engagement.apprenticeshipID,
                        domain: domain, sourceSuccessEventID: sourceSuccessEventID,
                        atTick: session.tick,
                        configuration: session.configuration.physicalChannelConfiguration
                    )
                    if try applyRecordedOperationIfActive(
                        .recordTeachingDemonstration(observation),
                        session: &session, recorder: &recorder
                    ) == nil { _ = try session.recordTeachingDemonstration(observation) }
                    let practiceAfter = session.practiceUnits(
                        agentID: engagement.studentID,
                        domain: domain
                    )
                    trace(
                        "autonomous teaching demonstration apprenticeship="
                            + "\(engagement.apprenticeshipID.rawValue) "
                            + "teacher=\(engagement.teacherID.rawValue) "
                            + "student=\(engagement.studentID.rawValue) "
                            + "domain=\(domain.rawValue) "
                            + "source=\(sourceSuccessEventID.rawValue) "
                            + "distance=\(observation.distanceManhattan) "
                            + "lineOfSight=\(observation.lineOfSight ? 1 : 0) "
                            + "studentPractice=\(practiceBefore)>"
                            + "\(practiceAfter) observationSkillDelta="
                            + "\(practiceAfter - practiceBefore)"
                    )
                } catch {
                    let reason = String(describing: error)
                        .replacingOccurrences(of: " ", with: "_")
                    trace(
                        "autonomous teaching demonstration deferred apprenticeship="
                            + "\(engagement.apprenticeshipID.rawValue) "
                            + "teacher=\(engagement.teacherID.rawValue) "
                            + "student=\(engagement.studentID.rawValue) "
                            + "domain=\(domain.rawValue) "
                            + "reason=\(reason)"
                    )
                }
            }
            if engagement.studentID == actorID, let skillPracticeEventID,
               let exposure = session.freshLearningExposures(
                   studentID: actorID, domain: domain
               ).first {
                do {
                    let practiceBeforeLink = session.practiceUnits(
                        agentID: actorID, domain: domain
                    )
                    if try applyRecordedOperationIfActive(
                        .linkGuidedPractice(
                            exposureID: exposure.exposureID,
                            studentSourceSuccessEventID: sourceSuccessEventID,
                            skillPracticeEventID: skillPracticeEventID
                        ), session: &session, recorder: &recorder
                    ) == nil {
                        _ = try session.linkGuidedPractice(
                            exposureID: exposure.exposureID,
                            studentSourceSuccessEventID: sourceSuccessEventID,
                            skillPracticeEventID: skillPracticeEventID
                        )
                    }
                    let practiceAfterLink = session.practiceUnits(
                        agentID: actorID,
                        domain: domain
                    )
                    trace(
                        "autonomous guided practice apprenticeship="
                            + "\(engagement.apprenticeshipID.rawValue) "
                            + "student=\(actorID.rawValue) domain=\(domain.rawValue) "
                            + "source=\(sourceSuccessEventID.rawValue) "
                            + "skillEvent=\(skillPracticeEventID.rawValue) "
                            + "practiceAfterOwnSuccess=\(practiceBeforeLink) "
                            + "practiceAfterLink=\(practiceAfterLink) "
                            + "guidedPracticeSkillDelta="
                            + "\(practiceAfterLink - practiceBeforeLink) materialBonus=0"
                    )
                } catch {
                    let reason = String(describing: error)
                        .replacingOccurrences(of: " ", with: "_")
                    trace(
                        "autonomous guided practice deferred apprenticeship="
                            + "\(engagement.apprenticeshipID.rawValue) "
                            + "student=\(actorID.rawValue) domain=\(domain.rawValue) "
                            + "reason=\(reason)"
                    )
                }
            }
        }
    }

    private func executeAutonomousAgriculture(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        occupied: [PhysicalBlockPosition],
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let intent = session.nextAgriculturalIntent(for: activity.candidate.actorID),
              intent.plotID.rawValue == activity.candidate.stableReference,
              let date = session.civilDate(),
              let actionID = AgentAgriculturalActionID(
                rawValue: "auto-agriculture:\(session.tick):\(activity.candidate.actorID.rawValue):\(intent.kind.rawValue)"
              ) else {
            throw ControllerError.feedbackBoundary("stale agricultural intent")
        }
        var candidate = session
        var candidateRecorder = recorder
        func publish(_ outcome: AgentAgriculturalActionOutcome) throws -> AgentAgriculturalActionRecord {
            try publishVerifiedAgriculturalAction(
                outcome,
                world: world,
                session: &candidate,
                recorder: &candidateRecorder
            )
        }
        switch intent.kind {
        case .till:
            _ = try agricultureExecutor.till(
                world: world, actor: actor, intent: intent, civilDate: date,
                occupiedPositions: occupied, materialGateway: materialCustodyGateway,
                physicalGateway: physicalActionGateway, actionID: actionID,
                publishAndVerify: publish
            )
        case .plant:
            _ = try agricultureExecutor.plant(
                world: world, actor: actor, intent: intent, civilDate: date,
                occupiedPositions: occupied, materialGateway: materialCustodyGateway,
                physicalGateway: physicalActionGateway, actionID: actionID,
                publishAndVerify: publish
            )
        case .harvest:
            _ = try agricultureExecutor.harvest(
                world: world, actor: actor, intent: intent, civilDate: date,
                occupiedPositions: occupied, materialGateway: materialCustodyGateway,
                physicalGateway: physicalActionGateway, actionID: actionID,
                publishAndVerify: publish
            )
        case .store:
            guard let container = nearestLiveAgricultureContainer(
                world: world, origin: actor.position, radius: 2
            ) else { throw ControllerError.feedbackBoundary("agriculture storage unavailable") }
            _ = try agricultureExecutor.storeHarvest(
                world: world, actor: actor, intent: intent, container: container,
                civilDate: date, seedReserveTarget: 0,
                retainedSeedQuantity:
                    session.agricultureSnapshot().plots.first(where: {
                        $0.plotID == intent.plotID
                    })?.cells.count ?? 0,
                materialGateway: materialCustodyGateway, actionID: actionID,
                publishAndVerify: publish
            )
        case .maturityObserved, .reconcile:
            throw ControllerError.feedbackBoundary("observation-only agriculture action")
        }
        session = candidate
        recorder = candidateRecorder
        try recordProductiveSourceSuccessIfPresent(
            domain: .agriculture,
            position: activity.candidate.physicalTarget ?? intent.position,
            receiptID: actionID.rawValue,
            session: &session,
            recorder: &recorder
        )
        return actionID.rawValue
    }

    private func executeAutonomousGathering(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        occupied: [PhysicalBlockPosition],
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let opportunity = session.wildSubsistenceSnapshot().opportunities.first(where: {
            $0.opportunityID.rawValue == activity.candidate.stableReference
                && $0.status == .selected
        }), let attemptID = AgentSubsistenceAttemptID(
            rawValue: "auto-gather:\(session.tick):\(opportunity.actorID.rawValue)"
        ) else { throw ControllerError.feedbackBoundary("stale gathering opportunity") }
        let target = PhysicalBlockPosition(
            x: opportunity.lastObservedPosition.x,
            y: opportunity.lastObservedPosition.y,
            z: opportunity.lastObservedPosition.z
        )
        let expected = world.getBlock(target.x, target.y, target.z) >> 4
        var candidate = session
        var candidateRecorder = recorder
        let physical = try wildSubsistenceExecutor.gather(
            world: world, actor: actor, target: target, expectedBlockID: expected,
            attemptID: attemptID.rawValue, occupiedPositions: occupied,
            physicalGateway: physicalActionGateway, materialGateway: materialCustodyGateway
        ) { ids, acquired, fingerprint, attribution in
            let outcome = AgentSubsistenceOutcome(
                attemptID: attemptID, opportunityID: opportunity.opportunityID,
                actorID: opportunity.actorID, strategy: .wildGathering,
                targetKey: opportunity.targetKey,
                targetPosition: opportunity.lastObservedPosition,
                sourceObservationEventID: opportunity.sourceObservationEventID,
                status: .succeeded, physicalCausalIDs: ids, acquiredItems: acquired,
                custodyFingerprint: fingerprint, attribution: attribution,
                completedAtTick: candidate.tick
            )
            if try applyRecordedOperationIfActive(
                .recordWildSubsistenceOutcome(outcome),
                session: &candidate, recorder: &candidateRecorder
            ) == nil { _ = try candidate.recordWildSubsistenceOutcome(outcome) }
        }
        guard physical.status == .succeeded else {
            throw ControllerError.feedbackBoundary("gathering physical outcome failed")
        }
        session = candidate
        recorder = candidateRecorder
        try recordProductiveSourceSuccessIfPresent(
            domain: .wildGathering,
            position: opportunity.lastObservedPosition,
            receiptID: attemptID.rawValue,
            session: &session,
            recorder: &recorder
        )
        return attemptID.rawValue
    }

    private func executeAutonomousFishing(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let opportunity = session.wildSubsistenceSnapshot().opportunities.first(where: {
            $0.opportunityID.rawValue == activity.candidate.stableReference
                && $0.status == .selected && $0.strategy == .fishing
        }), let rodSlot = actor.carriedItems.indices.first(where: { index in
            guard let stack = actor.carriedItems[index] else { return false }
            return itemDef(stack.id).name == "fishing_rod"
        }), let attemptID = AgentSubsistenceAttemptID(
            rawValue: "auto-fish:\(session.tick):\(opportunity.actorID.rawValue)"
        ) else { throw ControllerError.feedbackBoundary("stale fishing opportunity") }
        _ = try wildSubsistenceExecutor.approach(
            world: world, actor: actor,
            target: opportunity.lastObservedPosition, reach: 2,
            candidatePhysicalTransaction: activeCandidatePhysicalTransaction
        )
        var candidate = session
        var candidateRecorder = recorder
        let physical = try wildSubsistenceExecutor.fish(
            world: world, actor: actor, water: opportunity.lastObservedPosition,
            rodSlot: rodSlot, attemptID: attemptID.rawValue,
            materialGateway: materialCustodyGateway,
            candidatePhysicalTransaction: activeCandidatePhysicalTransaction
        ) { ids, acquired, fingerprint, attribution in
            let outcome = AgentSubsistenceOutcome(
                attemptID: attemptID, opportunityID: opportunity.opportunityID,
                actorID: opportunity.actorID, strategy: .fishing,
                targetKey: opportunity.targetKey,
                targetPosition: opportunity.lastObservedPosition,
                sourceObservationEventID: opportunity.sourceObservationEventID,
                status: .succeeded, physicalCausalIDs: ids, acquiredItems: acquired,
                custodyFingerprint: fingerprint, attribution: attribution,
                completedAtTick: candidate.tick
            )
            if try applyRecordedOperationIfActive(
                .recordWildSubsistenceOutcome(outcome),
                session: &candidate, recorder: &candidateRecorder
            ) == nil { _ = try candidate.recordWildSubsistenceOutcome(outcome) }
        }
        guard physical.status == .succeeded else {
            throw ControllerError.feedbackBoundary("fishing produced no material catch")
        }
        session = candidate
        recorder = candidateRecorder
        try recordProductiveSourceSuccessIfPresent(
            domain: .fishing,
            position: opportunity.lastObservedPosition,
            receiptID: attemptID.rawValue,
            session: &session,
            recorder: &recorder
        )
        return attemptID.rawValue
    }

    private func executeAutonomousHunting(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let opportunity = session.wildSubsistenceSnapshot().opportunities.first(where: {
            $0.opportunityID.rawValue == activity.candidate.stableReference
                && $0.status == .selected && $0.strategy == .hunting
        }), opportunity.targetKey.hasPrefix("animal:"),
              let separator = opportunity.targetKey.firstIndex(of: "@"),
              let weaponSlot = actor.carriedItems.indices.first(where: { index in
                  guard let stack = actor.carriedItems[index] else { return false }
                  return itemDef(stack.id).tool?.type == "sword"
              }), let attemptID = AgentSubsistenceAttemptID(
                  rawValue: "auto-hunt:\(session.tick):\(opportunity.actorID.rawValue)"
              ) else { throw ControllerError.feedbackBoundary("stale hunting opportunity") }
        let speciesStart = opportunity.targetKey.index(
            opportunity.targetKey.startIndex, offsetBy: "animal:".count
        )
        let species = String(opportunity.targetKey[speciesStart..<separator])
        let nearby = world.getEntitiesNear(
            Double(opportunity.lastObservedPosition.x) + 0.5,
            Double(opportunity.lastObservedPosition.y) + 0.5,
            Double(opportunity.lastObservedPosition.z) + 0.5,
            8
        ) { $0 is LivingEntity }
        let matches = nearby.prefix(64).compactMap { $0 as? LivingEntity }.filter {
            !$0.dead && $0.type == species
        }.map { entity in
            let position = AgentPosition(
                x: Int(entity.x.rounded(.down)), y: Int(entity.y.rounded(.down)),
                z: Int(entity.z.rounded(.down))
            )
            let distance = abs(position.x - opportunity.lastObservedPosition.x)
                + abs(position.y - opportunity.lastObservedPosition.y)
                + abs(position.z - opportunity.lastObservedPosition.z)
            return (entity, position, distance)
        }.filter { $0.2 <= 8 }.sorted {
            if $0.2 != $1.2 { return $0.2 < $1.2 }
            if $0.1.x != $1.1.x { return $0.1.x < $1.1.x }
            if $0.1.y != $1.1.y { return $0.1.y < $1.1.y }
            return $0.1.z < $1.1.z
        }
        guard let resolved = matches.first,
              matches.dropFirst().first.map({
                  $0.2 != resolved.2 || $0.1 != resolved.1
              }) ?? true else {
            throw ControllerError.feedbackBoundary("hunting target absent or physically ambiguous")
        }
        _ = try wildSubsistenceExecutor.approach(
            world: world, actor: actor, target: resolved.1, reach: 2,
            candidatePhysicalTransaction: activeCandidatePhysicalTransaction
        )
        var candidate = session
        var candidateRecorder = recorder
        let physical = try wildSubsistenceExecutor.hunt(
            world: world, actor: actor, target: resolved.0,
            expectedSpecies: species, weaponSlot: weaponSlot,
            attemptID: attemptID.rawValue, materialGateway: materialCustodyGateway,
            candidatePhysicalTransaction: activeCandidatePhysicalTransaction
        ) { ids, acquired, fingerprint, attribution in
            let outcome = AgentSubsistenceOutcome(
                attemptID: attemptID, opportunityID: opportunity.opportunityID,
                actorID: opportunity.actorID, strategy: .hunting,
                targetKey: opportunity.targetKey,
                targetPosition: opportunity.lastObservedPosition,
                sourceObservationEventID: opportunity.sourceObservationEventID,
                status: .succeeded, physicalCausalIDs: ids, acquiredItems: acquired,
                custodyFingerprint: fingerprint, attribution: attribution,
                completedAtTick: candidate.tick
            )
            if try applyRecordedOperationIfActive(
                .recordWildSubsistenceOutcome(outcome),
                session: &candidate, recorder: &candidateRecorder
            ) == nil { _ = try candidate.recordWildSubsistenceOutcome(outcome) }
        }
        guard physical.status == .succeeded else {
            throw ControllerError.feedbackBoundary("hunting produced no attributed death")
        }
        session = candidate
        recorder = candidateRecorder
        return attemptID.rawValue
    }

    private func executeAutonomousLivestock(
        activity: AgentAutonomousActivity,
        actor: PebbleAgentEmbodiment,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> String {
        guard let task = session.livestockSnapshot().activeTasks.first(where: {
            $0.taskID.rawValue == activity.candidate.stableReference && !$0.status.terminal
        }), let record = session.livestockSnapshot().managedAnimals.first(where: {
            $0.recordID == task.primaryAnimalRecordID
        }), let runtimeID = livestockRuntimeEntityIDByRecord[record.recordID],
              let animal = world.entityById[runtimeID] as? Animal,
              let actionID = AgentLivestockActionID(
                  rawValue: "auto-livestock:\(session.tick):\(task.taskID.rawValue)"
              ) else { throw ControllerError.feedbackBoundary("livestock target unresolved") }
        let physicalAnimalPosition = AgentPosition(
            x: Int(animal.x.rounded(.down)),
            y: Int(animal.y.rounded(.down)),
            z: Int(animal.z.rounded(.down))
        )
        try requireVerifiedAutonomousLivestockInteraction(
            actorPosition: actor.position,
            recordPosition: record.lastKnownPosition,
            physicalAnimalPosition: physicalAnimalPosition
        )
        var candidate = session
        var candidateRecorder = recorder
        func publish(_ outcome: AgentLivestockValidatedOutcome) throws {
            if try applyRecordedOperationIfActive(
                .applyLivestockOperation(.recordOutcome(outcome)),
                session: &candidate, recorder: &candidateRecorder
            ) == nil { try candidate.applyLivestockOperation(.recordOutcome(outcome)) }
        }
        switch task.kind {
        case .feed:
            let feedCount = actor.carriedItems.compactMap { $0 }.filter {
                animal.isFood($0)
            }.reduce(0) { $0 + $1.count }
            let reservedPlantingQuantity = task.taskID.rawValue
                .hasPrefix("renewable-feed-") ? 0 : 2
            let pressure = session.livestockFeedPressure(
                compatibleFeedQuantity: feedCount,
                reservedPlantingQuantity: reservedPlantingQuantity
            )
            guard pressure.eligibleFeedQuantity > 0 else {
                throw ControllerError.feedbackBoundary("planting reserve protects livestock feed")
            }
            _ = try livestockExecutor.feed(
                world: world, actor: actor, animal: animal,
                taskID: task.taskID, actionID: actionID, recordID: record.recordID,
                completedAtTick: session.tick,
                candidatePhysicalTransaction: activeCandidatePhysicalTransaction,
                publish: publish
            )
        case .collectProduct:
            guard let sheep = animal as? Sheep else {
                throw ControllerError.feedbackBoundary("managed animal has no supported product")
            }
            _ = try livestockExecutor.shear(
                world: world, actor: actor, sheep: sheep,
                taskID: task.taskID, actionID: actionID, recordID: record.recordID,
                materialGateway: materialCustodyGateway,
                completedAtTick: session.tick,
                candidatePhysicalTransaction: activeCandidatePhysicalTransaction,
                publish: publish
            )
        case .breed:
            let feedCount = actor.carriedItems.compactMap { $0 }.filter {
                animal.isFood($0)
            }.reduce(0) { $0 + $1.count }
            guard session.livestockFeedPressure(
                compatibleFeedQuantity: feedCount, reservedPlantingQuantity: 2
            ).eligibleFeedQuantity >= 2 else {
                throw ControllerError.feedbackBoundary("breeding deferred after planting reserve")
            }
            throw ControllerError.feedbackBoundary("breeding remains Core pair operation")
        case .observe, .herdMove, .recoverMissing, .slaughter:
            throw ControllerError.feedbackBoundary("livestock task has no one-tick executor")
        }
        session = candidate
        recorder = candidateRecorder
        try recordProductiveSourceSuccessIfPresent(
            domain: .livestock,
            position: record.lastKnownPosition,
            receiptID: actionID.rawValue,
            session: &session,
            recorder: &recorder
        )
        return actionID.rawValue
    }

    private func recordProductiveSourceSuccessIfPresent(
        domain: AgentAutonomousActivityDomain,
        position: AgentPosition,
        receiptID: String,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard session.productiveSourceLifecycleEnabled,
              let source = session.productiveSource(
                  domain: domain,
                  at: position
              ) else {
            return
        }
        let operation = AgentReplayOperation.recordProductiveSourceSuccess(
            sourceKey: source.sourceKey,
            expectedMaterialFingerprint: source.materialFingerprint,
            physicalReceiptID: receiptID
        )
        if try applyRecordedOperationIfActive(
            operation,
            session: &session,
            recorder: &recorder
        ) == nil {
            _ = try session.recordProductiveSourceSuccess(
                sourceKey: source.sourceKey,
                expectedMaterialFingerprint: source.materialFingerprint,
                physicalReceiptID: receiptID
            )
        }
    }

    func requireVerifiedAutonomousLivestockInteraction(
        actorPosition: AgentPosition,
        recordPosition: AgentPosition,
        physicalAnimalPosition: AgentPosition
    ) throws {
        let physicalReach = abs(actorPosition.x - physicalAnimalPosition.x)
            + abs(actorPosition.y - physicalAnimalPosition.y)
            + abs(actorPosition.z - physicalAnimalPosition.z)
        guard physicalReach <= 1, recordPosition == physicalAnimalPosition else {
            throw ControllerError.feedbackBoundary(
                "livestock target moved outside verified interaction reach"
            )
        }
    }
}
