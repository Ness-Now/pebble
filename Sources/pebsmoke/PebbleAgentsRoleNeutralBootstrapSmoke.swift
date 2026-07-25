import PebbleAgents

func runPebbleAgentsRoleNeutralBootstrapSmoke() {
    section("Gate B convergence role-neutral bootstrap contract")

    let neutral = AgentRoleNeutralBootstrapAudit(
        assignedPlanner: 0,
        assignedLivestockWorkers: 0,
        assignedWildWorker: 0,
        prequeuedProductiveTasks: 0,
        prestartedAgriculturePlans: 0,
        prestartedApprenticeships: 0,
        preloadedSkills: 0,
        preloadedProfessions: 0
    )
    check("role-neutral bootstrap accepts only zero assignments", neutral.isRoleNeutral)

    let assignedProductiveWork = AgentRoleNeutralBootstrapAudit(
        assignedPlanner: 1,
        assignedLivestockWorkers: 2,
        assignedWildWorker: 1,
        prequeuedProductiveTasks: 2,
        prestartedAgriculturePlans: 1,
        prestartedApprenticeships: 1,
        preloadedSkills: 3,
        preloadedProfessions: 2
    )
    check(
        "role-neutral bootstrap rejects assigned productive work",
        !assignedProductiveWork.isRoleNeutral
    )

    let negativeCounts = AgentRoleNeutralBootstrapAudit(
        assignedPlanner: -1,
        assignedLivestockWorkers: -1,
        assignedWildWorker: -1,
        prequeuedProductiveTasks: -1,
        prestartedAgriculturePlans: -1,
        prestartedApprenticeships: -1,
        preloadedSkills: -1,
        preloadedProfessions: -1
    )
    check(
        "role-neutral audit counters are bounded at zero",
        negativeCounts == neutral
    )
}
