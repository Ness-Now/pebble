/// Read-only audit values published by an integration fixture after it has
/// created physical opportunities. The fixture does not gain authority from
/// this type; normal product systems still own every later role and task.
public struct AgentRoleNeutralBootstrapAudit: Codable, Equatable, Sendable {
    public let assignedPlanner: Int
    public let assignedLivestockWorkers: Int
    public let assignedWildWorker: Int
    public let prequeuedProductiveTasks: Int
    public let prestartedAgriculturePlans: Int
    public let prestartedApprenticeships: Int
    public let preloadedSkills: Int
    public let preloadedProfessions: Int

    public init(
        assignedPlanner: Int,
        assignedLivestockWorkers: Int,
        assignedWildWorker: Int,
        prequeuedProductiveTasks: Int,
        prestartedAgriculturePlans: Int,
        prestartedApprenticeships: Int,
        preloadedSkills: Int,
        preloadedProfessions: Int
    ) {
        self.assignedPlanner = max(0, assignedPlanner)
        self.assignedLivestockWorkers = max(0, assignedLivestockWorkers)
        self.assignedWildWorker = max(0, assignedWildWorker)
        self.prequeuedProductiveTasks = max(0, prequeuedProductiveTasks)
        self.prestartedAgriculturePlans = max(0, prestartedAgriculturePlans)
        self.prestartedApprenticeships = max(0, prestartedApprenticeships)
        self.preloadedSkills = max(0, preloadedSkills)
        self.preloadedProfessions = max(0, preloadedProfessions)
    }

    public var isRoleNeutral: Bool {
        assignedPlanner == 0
            && assignedLivestockWorkers == 0
            && assignedWildWorker == 0
            && prequeuedProductiveTasks == 0
            && prestartedAgriculturePlans == 0
            && prestartedApprenticeships == 0
            && preloadedSkills == 0
            && preloadedProfessions == 0
    }
}
