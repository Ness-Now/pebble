public enum AgentEcologicalObservationError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case unknownObserver(AgentID)
    case invalidObservation(String)
    case scansPerTickReached
    case sequenceOverflow
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid ecological observation configuration: \(reason)"
        case .causalLedgerRequired:
            return "ecological observation requires the causal ledger"
        case .populationRequired:
            return "ecological observation requires population"
        case .alreadyEnabled:
            return "ecological observation already enabled"
        case .disabled:
            return "ecological observation disabled"
        case .unsafeDisable:
            return "ecological observation disable refused while durable state exists"
        case let .unknownObserver(id):
            return "unknown ecological observer \(id.rawValue)"
        case let .invalidObservation(reason):
            return "invalid ecological observation: \(reason)"
        case .scansPerTickReached:
            return "ecological observation scans per tick reached"
        case .sequenceOverflow:
            return "ecological observation sequence overflow"
        case let .invalidState(reason):
            return "invalid ecological observation state: \(reason)"
        }
    }
}

public enum AgentCivilSeason: String, Codable, CaseIterable, Sendable {
    case spring
    case summer
    case autumn
    case winter
}

public struct AgentCivilCalendarConfiguration: Codable, Equatable, Sendable {
    public let ticksPerCivilDay: Int
    public let daysPerSeason: Int
    public let seasonsPerYear: Int
    public let epochSimulationTick: Int
    public let epochYear: Int

    public init(
        ticksPerCivilDay: Int = 24,
        daysPerSeason: Int = 30,
        seasonsPerYear: Int = 4,
        epochSimulationTick: Int = 0,
        epochYear: Int = 1
    ) throws {
        guard (1...1_000_000).contains(ticksPerCivilDay) else {
            throw AgentEcologicalObservationError.invalidConfiguration("ticks per civil day")
        }
        guard (1...366).contains(daysPerSeason) else {
            throw AgentEcologicalObservationError.invalidConfiguration("days per season")
        }
        guard seasonsPerYear == AgentCivilSeason.allCases.count else {
            throw AgentEcologicalObservationError.invalidConfiguration("seasons per year")
        }
        guard epochSimulationTick >= 0, epochYear >= 1 else {
            throw AgentEcologicalObservationError.invalidConfiguration("calendar epoch")
        }
        self.ticksPerCivilDay = ticksPerCivilDay
        self.daysPerSeason = daysPerSeason
        self.seasonsPerYear = seasonsPerYear
        self.epochSimulationTick = epochSimulationTick
        self.epochYear = epochYear
    }

    public static let live = try! AgentCivilCalendarConfiguration()

    public func date(atSimulationTick tick: Int) -> AgentCivilDate? {
        guard tick >= epochSimulationTick else { return nil }
        let elapsedTicks = tick - epochSimulationTick
        let absoluteDay = elapsedTicks / ticksPerCivilDay
        let daysPerYear = daysPerSeason * seasonsPerYear
        let yearOffset = absoluteDay / daysPerYear
        let yearDayIndex = absoluteDay % daysPerYear
        let seasonIndex = yearDayIndex / daysPerSeason
        guard seasonIndex < AgentCivilSeason.allCases.count else { return nil }
        let (year, overflow) = epochYear.addingReportingOverflow(yearOffset)
        guard !overflow else { return nil }
        return AgentCivilDate(
            day: yearDayIndex % daysPerSeason + 1,
            season: AgentCivilSeason.allCases[seasonIndex],
            year: year,
            dayOfYear: yearDayIndex + 1,
            absoluteDay: absoluteDay,
            simulationTick: tick
        )
    }
}

public struct AgentCivilDate: Codable, Equatable, Sendable {
    /// One-based day within the civil season.
    public let day: Int
    public let season: AgentCivilSeason
    public let year: Int
    public let dayOfYear: Int
    public let absoluteDay: Int
    public let simulationTick: Int

    public init(
        day: Int,
        season: AgentCivilSeason,
        year: Int,
        dayOfYear: Int,
        absoluteDay: Int,
        simulationTick: Int
    ) {
        self.day = day
        self.season = season
        self.year = year
        self.dayOfYear = dayOfYear
        self.absoluteDay = absoluteDay
        self.simulationTick = simulationTick
    }
}

public enum AgentEcologicalRenewability: String, Codable, CaseIterable, Sendable {
    case knownRenewable
    case knownDepletable
    case conditional
    case unknown
}

public enum AgentEcologicalScanCompletion: String, Codable, CaseIterable, Sendable {
    case complete
    case chunkUnavailable
    case scanBudgetExceeded
}

public enum AgentAnimalLifeStage: String, Codable, CaseIterable, Sendable {
    case adult
    case juvenile
    case unknown
}

public enum AgentWeatherKind: String, Codable, CaseIterable, Sendable {
    case clear
    case rain
    case thunder
}

public enum AgentPhysicalTimeOfDay: String, Codable, CaseIterable, Sendable {
    case dawn
    case day
    case dusk
    case night
}

public struct AgentBiomeObservation: Codable, Equatable, Sendable {
    public let biomeKey: String
    public let position: AgentPosition

    public init(biomeKey: String, position: AgentPosition) {
        self.biomeKey = biomeKey
        self.position = position
    }
}

public struct AgentWaterAffordance: Codable, Equatable, Sendable {
    public let fluidKey: String
    public let position: AgentPosition
    public let sourceBlock: Bool

    public init(fluidKey: String, position: AgentPosition, sourceBlock: Bool) {
        self.fluidKey = fluidKey
        self.position = position
        self.sourceBlock = sourceBlock
    }
}

public struct AgentSoilAffordance: Codable, Equatable, Sendable {
    public let blockKey: String
    public let position: AgentPosition
    public let tillable: Bool
    public let alreadyFarmland: Bool
    public let hydrated: Bool?
    public let supportsCrop: Bool

    public init(
        blockKey: String,
        position: AgentPosition,
        tillable: Bool,
        alreadyFarmland: Bool,
        hydrated: Bool?,
        supportsCrop: Bool
    ) {
        self.blockKey = blockKey
        self.position = position
        self.tillable = tillable
        self.alreadyFarmland = alreadyFarmland
        self.hydrated = hydrated
        self.supportsCrop = supportsCrop
    }
}

public struct AgentCropObservation: Codable, Equatable, Sendable {
    public let cropKey: String
    public let position: AgentPosition
    public let growthStage: Int
    public let maximumGrowthStage: Int
    public let mature: Bool
    public let supportBlockKey: String?

    public init(
        cropKey: String,
        position: AgentPosition,
        growthStage: Int,
        maximumGrowthStage: Int,
        mature: Bool,
        supportBlockKey: String?
    ) {
        self.cropKey = cropKey
        self.position = position
        self.growthStage = growthStage
        self.maximumGrowthStage = maximumGrowthStage
        self.mature = mature
        self.supportBlockKey = supportBlockKey
    }
}

public struct AgentPlantObservation: Codable, Equatable, Sendable {
    public let plantKey: String
    public let position: AgentPosition
    public let renewability: AgentEcologicalRenewability

    public init(
        plantKey: String,
        position: AgentPosition,
        renewability: AgentEcologicalRenewability
    ) {
        self.plantKey = plantKey
        self.position = position
        self.renewability = renewability
    }
}

public struct AgentAnimalObservation: Codable, Equatable, Sendable {
    public let speciesKey: String
    public let position: AgentPosition
    public let count: Int
    public let lifeStage: AgentAnimalLifeStage
    public let breedableAffordanceObservable: Bool

    public init(
        speciesKey: String,
        position: AgentPosition,
        count: Int,
        lifeStage: AgentAnimalLifeStage,
        breedableAffordanceObservable: Bool
    ) {
        self.speciesKey = speciesKey
        self.position = position
        self.count = count
        self.lifeStage = lifeStage
        self.breedableAffordanceObservable = breedableAffordanceObservable
    }
}

public struct AgentFishingAffordance: Codable, Equatable, Sendable {
    public let position: AgentPosition
    public let waterKey: String
    public let candidate: Bool

    public init(position: AgentPosition, waterKey: String, candidate: Bool) {
        self.position = position
        self.waterKey = waterKey
        self.candidate = candidate
    }
}

public struct AgentWeatherObservation: Codable, Equatable, Sendable {
    public let kind: AgentWeatherKind
    public let raining: Bool
    public let thundering: Bool

    public init(kind: AgentWeatherKind, raining: Bool, thundering: Bool) {
        self.kind = kind
        self.raining = raining
        self.thundering = thundering
    }
}

public struct AgentPhysicalWorldTimeObservation: Codable, Equatable, Sendable {
    public let worldTick: Int
    public let dayTime: Int
    public let timeOfDay: AgentPhysicalTimeOfDay
    public let daylightCycleEnabled: Bool

    public init(
        worldTick: Int,
        dayTime: Int,
        timeOfDay: AgentPhysicalTimeOfDay,
        daylightCycleEnabled: Bool
    ) {
        self.worldTick = worldTick
        self.dayTime = dayTime
        self.timeOfDay = timeOfDay
        self.daylightCycleEnabled = daylightCycleEnabled
    }
}

public struct AgentEcologicalScanDiagnostics: Codable, Equatable, Sendable {
    public let radius: Int
    public let cellsConsidered: Int
    public let worldReads: Int
    public let chunksTouched: Int
    public let chunksUnavailable: Int
    public let entitiesConsidered: Int
    public let resultsEmitted: Int
    public let cacheHits: Int
    public let cacheMisses: Int
    public let completion: AgentEcologicalScanCompletion

    public init(
        radius: Int,
        cellsConsidered: Int,
        worldReads: Int,
        chunksTouched: Int,
        chunksUnavailable: Int,
        entitiesConsidered: Int,
        resultsEmitted: Int,
        cacheHits: Int,
        cacheMisses: Int,
        completion: AgentEcologicalScanCompletion
    ) {
        self.radius = radius
        self.cellsConsidered = cellsConsidered
        self.worldReads = worldReads
        self.chunksTouched = chunksTouched
        self.chunksUnavailable = chunksUnavailable
        self.entitiesConsidered = entitiesConsidered
        self.resultsEmitted = resultsEmitted
        self.cacheHits = cacheHits
        self.cacheMisses = cacheMisses
        self.completion = completion
    }
}

public struct AgentEcologicalObservation: Codable, Equatable, Sendable {
    public let observerID: AgentID
    public let origin: AgentPosition
    public let worldContextKey: String
    public let dimensionKey: String
    public let observedAtSimulationTick: Int
    public let physicalWorldTick: Int
    public let civilDate: AgentCivilDate
    public let biome: AgentBiomeObservation?
    public let water: [AgentWaterAffordance]
    public let soils: [AgentSoilAffordance]
    public let crops: [AgentCropObservation]
    public let plants: [AgentPlantObservation]
    public let animals: [AgentAnimalObservation]
    public let fishing: [AgentFishingAffordance]
    public let weather: AgentWeatherObservation
    public let physicalTime: AgentPhysicalWorldTimeObservation
    public let diagnostics: AgentEcologicalScanDiagnostics
    public let expiresAtSimulationTick: Int
    public let digest: String

    public init(
        observerID: AgentID,
        origin: AgentPosition,
        worldContextKey: String,
        dimensionKey: String,
        observedAtSimulationTick: Int,
        physicalWorldTick: Int,
        civilDate: AgentCivilDate,
        biome: AgentBiomeObservation?,
        water: [AgentWaterAffordance],
        soils: [AgentSoilAffordance],
        crops: [AgentCropObservation],
        plants: [AgentPlantObservation],
        animals: [AgentAnimalObservation],
        fishing: [AgentFishingAffordance],
        weather: AgentWeatherObservation,
        physicalTime: AgentPhysicalWorldTimeObservation,
        diagnostics: AgentEcologicalScanDiagnostics,
        expiresAtSimulationTick: Int
    ) {
        self.observerID = observerID
        self.origin = origin
        self.worldContextKey = worldContextKey
        self.dimensionKey = dimensionKey
        self.observedAtSimulationTick = observedAtSimulationTick
        self.physicalWorldTick = physicalWorldTick
        self.civilDate = civilDate
        self.biome = biome
        self.water = water.sorted(by: Self.waterSort)
        self.soils = soils.sorted(by: Self.soilSort)
        self.crops = crops.sorted(by: Self.cropSort)
        self.plants = plants.sorted(by: Self.plantSort)
        self.animals = animals.sorted(by: Self.animalSort)
        self.fishing = fishing.sorted(by: Self.fishingSort)
        self.weather = weather
        self.physicalTime = physicalTime
        self.diagnostics = diagnostics
        self.expiresAtSimulationTick = expiresAtSimulationTick
        digest = AgentEcologicalObservationDigest.make(Self.canonicalText(
            observerID: observerID, origin: origin,
            worldContextKey: worldContextKey, dimensionKey: dimensionKey,
            observedAtSimulationTick: observedAtSimulationTick,
            physicalWorldTick: physicalWorldTick, civilDate: civilDate,
            biome: biome, water: self.water, soils: self.soils,
            crops: self.crops, plants: self.plants, animals: self.animals,
            fishing: self.fishing, weather: weather, physicalTime: physicalTime,
            diagnostics: diagnostics, expiresAtSimulationTick: expiresAtSimulationTick
        ))
    }

    public func isFresh(atSimulationTick tick: Int) -> Bool {
        tick >= observedAtSimulationTick && tick <= expiresAtSimulationTick
    }

    public func hasValidDigest() -> Bool { digest == recomputedDigest() }

    public func recomputedDigest() -> String {
        AgentEcologicalObservationDigest.make(Self.canonicalText(
            observerID: observerID, origin: origin,
            worldContextKey: worldContextKey, dimensionKey: dimensionKey,
            observedAtSimulationTick: observedAtSimulationTick,
            physicalWorldTick: physicalWorldTick, civilDate: civilDate,
            biome: biome, water: water.sorted(by: Self.waterSort),
            soils: soils.sorted(by: Self.soilSort), crops: crops.sorted(by: Self.cropSort),
            plants: plants.sorted(by: Self.plantSort), animals: animals.sorted(by: Self.animalSort),
            fishing: fishing.sorted(by: Self.fishingSort), weather: weather,
            physicalTime: physicalTime, diagnostics: diagnostics,
            expiresAtSimulationTick: expiresAtSimulationTick
        ))
    }

    public static func positionSort(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Bool {
        if lhs.x != rhs.x { return lhs.x < rhs.x }
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        return lhs.z < rhs.z
    }

    public static func waterSort(_ lhs: AgentWaterAffordance, _ rhs: AgentWaterAffordance) -> Bool {
        if lhs.position != rhs.position { return positionSort(lhs.position, rhs.position) }
        return lhs.fluidKey < rhs.fluidKey
    }

    public static func soilSort(_ lhs: AgentSoilAffordance, _ rhs: AgentSoilAffordance) -> Bool {
        if lhs.position != rhs.position { return positionSort(lhs.position, rhs.position) }
        return lhs.blockKey < rhs.blockKey
    }

    public static func cropSort(_ lhs: AgentCropObservation, _ rhs: AgentCropObservation) -> Bool {
        if lhs.position != rhs.position { return positionSort(lhs.position, rhs.position) }
        return lhs.cropKey < rhs.cropKey
    }

    public static func plantSort(_ lhs: AgentPlantObservation, _ rhs: AgentPlantObservation) -> Bool {
        if lhs.position != rhs.position { return positionSort(lhs.position, rhs.position) }
        return lhs.plantKey < rhs.plantKey
    }

    public static func animalSort(_ lhs: AgentAnimalObservation, _ rhs: AgentAnimalObservation) -> Bool {
        if lhs.position != rhs.position { return positionSort(lhs.position, rhs.position) }
        if lhs.speciesKey != rhs.speciesKey { return lhs.speciesKey < rhs.speciesKey }
        return lhs.lifeStage.rawValue < rhs.lifeStage.rawValue
    }

    public static func fishingSort(_ lhs: AgentFishingAffordance, _ rhs: AgentFishingAffordance) -> Bool {
        if lhs.position != rhs.position { return positionSort(lhs.position, rhs.position) }
        return lhs.waterKey < rhs.waterKey
    }

    private static func canonicalText(
        observerID: AgentID,
        origin: AgentPosition,
        worldContextKey: String,
        dimensionKey: String,
        observedAtSimulationTick: Int,
        physicalWorldTick: Int,
        civilDate: AgentCivilDate,
        biome: AgentBiomeObservation?,
        water: [AgentWaterAffordance],
        soils: [AgentSoilAffordance],
        crops: [AgentCropObservation],
        plants: [AgentPlantObservation],
        animals: [AgentAnimalObservation],
        fishing: [AgentFishingAffordance],
        weather: AgentWeatherObservation,
        physicalTime: AgentPhysicalWorldTimeObservation,
        diagnostics: AgentEcologicalScanDiagnostics,
        expiresAtSimulationTick: Int
    ) -> String {
        func point(_ value: AgentPosition) -> String { "\(value.x),\(value.y),\(value.z)" }
        let fields = [
            "observer=\(observerID.rawValue)", "origin=\(point(origin))",
            "world=\(worldContextKey)", "dimension=\(dimensionKey)",
            "ticks=\(observedAtSimulationTick),\(physicalWorldTick),\(expiresAtSimulationTick)",
            "civil=\(civilDate.year),\(civilDate.season.rawValue),\(civilDate.day),\(civilDate.absoluteDay)",
            "biome=\(biome.map { "\($0.biomeKey)@\(point($0.position))" } ?? "none")",
            "water=" + water.map { "\($0.fluidKey)@\(point($0.position)):\($0.sourceBlock ? 1 : 0)" }.joined(separator: ";"),
            "soils=" + soils.map { "\($0.blockKey)@\(point($0.position)):\($0.tillable ? 1 : 0):\($0.alreadyFarmland ? 1 : 0):\($0.hydrated.map { $0 ? "1" : "0" } ?? "u"):\($0.supportsCrop ? 1 : 0)" }.joined(separator: ";"),
            "crops=" + crops.map { "\($0.cropKey)@\(point($0.position)):\($0.growthStage)/\($0.maximumGrowthStage):\($0.mature ? 1 : 0):\($0.supportBlockKey ?? "none")" }.joined(separator: ";"),
            "plants=" + plants.map { "\($0.plantKey)@\(point($0.position)):\($0.renewability.rawValue)" }.joined(separator: ";"),
            "animals=" + animals.map { "\($0.speciesKey)@\(point($0.position)):\($0.count):\($0.lifeStage.rawValue):\($0.breedableAffordanceObservable ? 1 : 0)" }.joined(separator: ";"),
            "fishing=" + fishing.map { "\($0.waterKey)@\(point($0.position)):\($0.candidate ? 1 : 0)" }.joined(separator: ";"),
            "weather=\(weather.kind.rawValue):\(weather.raining ? 1 : 0):\(weather.thundering ? 1 : 0)",
            "time=\(physicalTime.worldTick):\(physicalTime.dayTime):\(physicalTime.timeOfDay.rawValue):\(physicalTime.daylightCycleEnabled ? 1 : 0)",
            "scan=\(diagnostics.radius):\(diagnostics.cellsConsidered):\(diagnostics.worldReads):\(diagnostics.chunksTouched):\(diagnostics.chunksUnavailable):\(diagnostics.entitiesConsidered):\(diagnostics.resultsEmitted):\(diagnostics.cacheHits):\(diagnostics.cacheMisses):\(diagnostics.completion.rawValue)",
        ]
        return fields.joined(separator: "|")
    }
}

public struct AgentEcologicalObservationConfiguration: Codable, Equatable, Sendable {
    public let radius: Int
    public let verticalRadius: Int
    public let maximumCellsPerScan: Int
    public let maximumChunksPerScan: Int
    public let maximumEntitiesPerScan: Int
    public let maximumResultsPerScan: Int
    public let maximumWorldReadsPerScan: Int
    public let maximumScansPerSimulationTick: Int
    public let maximumRetainedObservations: Int
    public let maximumRetainedObservationsPerAgent: Int
    public let dynamicFreshnessTicks: Int
    public let waterSoilFreshnessTicks: Int
    public let biomeFreshnessTicks: Int
    public let calendar: AgentCivilCalendarConfiguration

    public init(
        radius: Int = 4,
        verticalRadius: Int = 2,
        maximumCellsPerScan: Int = 512,
        maximumChunksPerScan: Int = 4,
        maximumEntitiesPerScan: Int = 64,
        maximumResultsPerScan: Int = 128,
        maximumWorldReadsPerScan: Int = 1_024,
        maximumScansPerSimulationTick: Int = 32,
        maximumRetainedObservations: Int = 128,
        maximumRetainedObservationsPerAgent: Int = 16,
        dynamicFreshnessTicks: Int = 4,
        waterSoilFreshnessTicks: Int = 16,
        biomeFreshnessTicks: Int = 256,
        calendar: AgentCivilCalendarConfiguration = .live
    ) throws {
        guard (1...16).contains(radius), (0...8).contains(verticalRadius) else {
            throw AgentEcologicalObservationError.invalidConfiguration("radius")
        }
        guard (1...4_096).contains(maximumCellsPerScan),
              (1...64).contains(maximumChunksPerScan),
              (1...1_024).contains(maximumEntitiesPerScan),
              (1...2_048).contains(maximumResultsPerScan),
              (1...8_192).contains(maximumWorldReadsPerScan) else {
            throw AgentEcologicalObservationError.invalidConfiguration("scan budgets")
        }
        guard (1...256).contains(maximumScansPerSimulationTick),
              (1...8_192).contains(maximumRetainedObservations),
              (1...1_024).contains(maximumRetainedObservationsPerAgent),
              maximumRetainedObservationsPerAgent <= maximumRetainedObservations else {
            throw AgentEcologicalObservationError.invalidConfiguration("retention")
        }
        guard (1...1_024).contains(dynamicFreshnessTicks),
              dynamicFreshnessTicks <= waterSoilFreshnessTicks,
              waterSoilFreshnessTicks <= biomeFreshnessTicks,
              biomeFreshnessTicks <= 65_536 else {
            throw AgentEcologicalObservationError.invalidConfiguration("freshness")
        }
        self.radius = radius
        self.verticalRadius = verticalRadius
        self.maximumCellsPerScan = maximumCellsPerScan
        self.maximumChunksPerScan = maximumChunksPerScan
        self.maximumEntitiesPerScan = maximumEntitiesPerScan
        self.maximumResultsPerScan = maximumResultsPerScan
        self.maximumWorldReadsPerScan = maximumWorldReadsPerScan
        self.maximumScansPerSimulationTick = maximumScansPerSimulationTick
        self.maximumRetainedObservations = maximumRetainedObservations
        self.maximumRetainedObservationsPerAgent = maximumRetainedObservationsPerAgent
        self.dynamicFreshnessTicks = dynamicFreshnessTicks
        self.waterSoilFreshnessTicks = waterSoilFreshnessTicks
        self.biomeFreshnessTicks = biomeFreshnessTicks
        self.calendar = calendar
    }

    public static let live = try! AgentEcologicalObservationConfiguration()
}

public struct AgentEcologicalObservationRecord: Codable, Equatable, Sendable {
    public let sequence: UInt64
    public let observation: AgentEcologicalObservation
    public let causalEventID: AgentCausalEventID

    public init(
        sequence: UInt64,
        observation: AgentEcologicalObservation,
        causalEventID: AgentCausalEventID
    ) {
        self.sequence = sequence
        self.observation = observation
        self.causalEventID = causalEventID
    }
}

public struct AgentEcologicalObservationEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var observations: Int

    public init(observations: Int = 0) {
        self.observations = max(0, observations)
    }
}

public struct AgentEcologicalObservationState: Codable, Equatable, Sendable {
    public let configuration: AgentEcologicalObservationConfiguration
    public internal(set) var observations: [AgentEcologicalObservationRecord]
    public internal(set) var totalObservationCount: UInt64
    public internal(set) var evictionCounts: AgentEcologicalObservationEvictionCounts
    public internal(set) var initializedEventID: AgentCausalEventID
    public internal(set) var lastObservationEventID: AgentCausalEventID
    public internal(set) var transitionTick: Int
    public internal(set) var observationsAtTick: Int

    public init(
        configuration: AgentEcologicalObservationConfiguration,
        observations: [AgentEcologicalObservationRecord],
        totalObservationCount: UInt64,
        evictionCounts: AgentEcologicalObservationEvictionCounts,
        initializedEventID: AgentCausalEventID,
        lastObservationEventID: AgentCausalEventID,
        transitionTick: Int,
        observationsAtTick: Int
    ) {
        self.configuration = configuration
        self.observations = observations.sorted { $0.sequence < $1.sequence }
        self.totalObservationCount = totalObservationCount
        self.evictionCounts = evictionCounts
        self.initializedEventID = initializedEventID
        self.lastObservationEventID = lastObservationEventID
        self.transitionTick = transitionTick
        self.observationsAtTick = observationsAtTick
    }
}

public struct AgentEcologicalObservationSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentEcologicalObservationConfiguration?
    public let civilDate: AgentCivilDate?
    public let observations: [AgentEcologicalObservationRecord]
    public let freshCount: Int
    public let staleCount: Int
    public let totalObservationCount: UInt64
    public let scanCount: Int
    public let worldReadCount: Int
    public let cacheHitCount: Int
    public let cacheMissCount: Int
    public let evictionCounts: AgentEcologicalObservationEvictionCounts
    public let digest: String
}

/// Read-only classification of the independent authority that proves an
/// ecological observer existed and was alive at the observation boundary.
/// This is derived during validation and is not a second durable history.
public enum AgentHistoricalEcologicalObserverClassification: String,
    Codable, Equatable, Sendable {
    case activeAtObservation
    case deceasedAfterObservationRetained
}

public struct AgentHistoricalEcologicalObservationValidation: Equatable,
    Sendable {
    public let sequence: UInt64
    public let observerID: AgentID
    public let classification: AgentHistoricalEcologicalObserverClassification

    public init(
        sequence: UInt64,
        observerID: AgentID,
        classification: AgentHistoricalEcologicalObserverClassification
    ) {
        self.sequence = sequence
        self.observerID = observerID
        self.classification = classification
    }
}

public enum AgentEcologicalObservationDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
