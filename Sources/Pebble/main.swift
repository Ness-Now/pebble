// Pebble — native macOS app shell. Window + MTKView, NSEvent → key-code-style
// key codes, pointer capture, the frame loop, and the GameHost bridge wiring
// GameCore to the UI stack (title/menus/HUD/screens) and renderer.

import AppKit
import ImageIO
import MetalKit
import PebbleAgents
import PebbleCore

func suppressAutomaticPauseForDisposableWorldProof(
    environment: [String: String] = ProcessInfo.processInfo.environment
) -> Bool {
    environment["PEBBLE_CMD"] != nil
        && environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
}

func disposableWorldProofPauseContractIsValid() -> Bool {
    !suppressAutomaticPauseForDisposableWorldProof(environment: [:])
        && !suppressAutomaticPauseForDisposableWorldProof(environment: ["PEBBLE_CMD": "/lab"])
        && !suppressAutomaticPauseForDisposableWorldProof(environment: [
            "PEBBLE_CMD": "/lab",
            "PEBBLELAB_DISPOSABLE_WORLD_PROOF": "0",
        ])
        && suppressAutomaticPauseForDisposableWorldProof(environment: [
            "PEBBLE_CMD": "/lab",
            "PEBBLELAB_DISPOSABLE_WORLD_PROOF": "1",
        ])
}

// ---------------------------------------------------------------------------
// NSEvent keyCode (kVK_*) → internal key-code strings (GameCore keybinds)
// ---------------------------------------------------------------------------
let KEYCODE_MAP: [UInt16: String] = [
    0: "KeyA", 1: "KeyS", 2: "KeyD", 3: "KeyF", 4: "KeyH", 5: "KeyG", 6: "KeyZ", 7: "KeyX",
    8: "KeyC", 9: "KeyV", 11: "KeyB", 12: "KeyQ", 13: "KeyW", 14: "KeyE", 15: "KeyR",
    16: "KeyY", 17: "KeyT", 18: "Digit1", 19: "Digit2", 20: "Digit3", 21: "Digit4",
    22: "Digit6", 23: "Digit5", 24: "Equal", 25: "Digit9", 26: "Digit7", 27: "Minus",
    28: "Digit8", 29: "Digit0", 30: "BracketRight", 31: "KeyO", 32: "KeyU", 33: "BracketLeft",
    34: "KeyI", 35: "KeyP", 36: "Enter", 37: "KeyL", 38: "KeyJ", 39: "Quote", 40: "KeyK",
    41: "Semicolon", 42: "Backslash", 43: "Comma", 44: "Slash", 45: "KeyN", 46: "KeyM",
    47: "Period", 48: "Tab", 49: "Space", 50: "Backquote", 51: "Backspace", 53: "Escape",
    96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 109: "F10",
    111: "F12", 118: "F4", 120: "F2", 122: "F1", 123: "ArrowLeft", 124: "ArrowRight",
    125: "ArrowDown", 126: "ArrowUp", 117: "Delete",
    10: "IntlBackslash", // ISO § key
    82: "Numpad0", 83: "Numpad1", 84: "Numpad2", 85: "Numpad3", 86: "Numpad4",
    87: "Numpad5", 88: "Numpad6", 89: "Numpad7", 91: "Numpad8", 92: "Numpad9",
    65: "NumpadDecimal", 67: "NumpadMultiply", 69: "NumpadAdd", 75: "NumpadDivide",
    76: "NumpadEnter", 78: "NumpadSubtract", 81: "NumpadEqual",
]

/// bundle resource lookup with a dev fallback: under `swift run` the
/// resourcePath is .build/<config> (no bundle assembly), so walk up to the
/// repo's packaging/ — otherwise dev builds silently lose the title photo,
/// wordmark and default pack
func bundleResourcePath(_ name: String) -> String? {
    if let rp = Bundle.main.resourcePath {
        let p = rp + "/" + name
        if FileManager.default.fileExists(atPath: p) { return p }
    }
    var dir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    for _ in 0..<6 {
        let cand = dir.appendingPathComponent("packaging/" + name).path
        if FileManager.default.fileExists(atPath: cand) { return cand }
        dir = dir.deletingLastPathComponent()
    }
    return nil
}

// ---------------------------------------------------------------------------
// host bridge: GameCore ↔ UI stack / renderer / audio
// ---------------------------------------------------------------------------
final class HostBridge: GameHost {
    weak var app: AppDelegate?
    var ui: UIManager { app!.ui }
    var hud: HUD { app!.hud }
    var game: GameCore { app!.game }

    func hasScreen() -> Bool { app?.ui.hasScreen() ?? false }
    func screenPausesGame() -> Bool { app?.ui.current()?.pausesGame ?? false }

    func openScreen(_ kind: String, _ data: ScreenData?) {
        guard let app else { return }
        switch kind {
        case "crafting": ui.open(CraftingScreen(), game)
        case "inventory": ui.open(InventoryScreen(), game)
        case "creative": ui.open(CreativeScreen(), game)
        case "chest":
            if let be = data?.be {
                ui.open(ChestScreen(be, data?.title ?? "Chest", data?.other), game)
            }
        case "ender_chest":
            let p = game.player!
            ui.open(ChestScreen(items: { p.enderChest }, set: { p.enderChest[$0] = $1 },
                                count: p.enderChest.count, "Ender Chest"), game)
        case "furnace":
            if let be = data?.be { ui.open(FurnaceScreen(be), game) }
        case "brewing":
            if let be = data?.be { ui.open(BrewingScreen(be), game) }
        case "enchanting":
            ui.open(EnchantingScreen((data?.x ?? 0, data?.y ?? 0, data?.z ?? 0)), game)
        case "anvil":
            ui.open(AnvilScreen((data?.x ?? 0, data?.y ?? 0, data?.z ?? 0, data?.damage ?? 0)), game)
        case "grindstone": ui.open(GrindstoneScreen(), game)
        case "stonecutter": ui.open(StonecutterScreen(), game)
        case "smithing": ui.open(SmithingScreen(), game)
        case "beacon":
            if let be = data?.be { ui.open(BeaconScreen(be), game) }
        case "sign":
            ui.open(SignScreen(data?.be, (data?.x ?? 0, data?.y ?? 0, data?.z ?? 0)), game)
        case "toast":
            hud.showActionBar(data?.text ?? "")
        default:
            break
        }
        if ui.hasScreen() { app.gameView.releaseMouse() }
    }
    func openTrading(_ villager: Mob) {
        ui.open(TradingScreen(villager), game)
        app?.gameView.releaseMouse()
    }
    func openVehicleChest(_ kind: String, _ vehicle: Entity) {
        let title = kind == "boat_chest" ? "Chest Boat" : "Minecart with Chest"
        if let boat = vehicle as? Boat {
            ui.open(ChestScreen(vehicle: boat, title), game)
        } else if let cart = vehicle as? Minecart {
            ui.open(ChestScreen(vehicle: cart, title), game)
        }
        app?.gameView.releaseMouse()
    }
    func openChat(_ prefix: String) {
        let g = game
        ui.open(ChatScreen({ cmd in runCommand(g, cmd) }, prefix), g)
        app?.gameView.releaseMouse()
    }
    func openDeathScreen(_ message: String) {
        ui.open(DeathScreen(message), game)
    }
    func openPauseScreen() {
        ui.open(PauseScreen(), game)
        app?.gameView.releaseMouse()
    }
    func openTitleScreen() {
        ui.titlePhoto = app?.renderer.titleBgTex != nil; ui.titleLogo = app?.renderer.titleLogoTex != nil
        ui.open(TitleScreen(), game)
        app?.gameView.releaseMouse()
    }
    func closeAllScreens() { ui.closeAll(game) }
    func releasePointer() { app?.gameView.releaseMouse() }

    func showActionBar(_ text: String, _ time: Int) {
        hud.showActionBar(text)
        hud.actionBarTime = time
    }
    func pushChat(_ line: String) { Pebble_pushChat(line) }
    func pushToast(_ adv: AdvancementDef) { hud.pushToast(adv) }
    func setBossBars(_ bars: [BossBarInfo]) { hud.bossBars = bars }

    func playSound(_ name: String, _ x: Double, _ y: Double, _ z: Double, _ volume: Double, _ pitch: Double) {
        guard let app else { return }
        if name.hasPrefix("jukebox.play.") {
            app.audio.playDisc(name, x, y, z)
            return
        }
        app.audio.play(name, x, y, z, volume, pitch)
    }
    func playUI(_ name: String) { app?.audio.playUI(name) }
    func setAudioEnvironment(_ underwater: Bool, _ caveFactor: Double) {
        app?.audio.setEnvironment(underwater, caveFactor)
    }
    func setAudioListener(_ x: Double, _ y: Double, _ z: Double, _ yaw: Double) {
        app?.audio.setListener(x, y, z, yaw)
    }
    func tickMusic(_ mood: String, _ enabled: Bool) { app?.audio.tickMusic(mood, enabled) }
    func stopDisc() { app?.audio.stopDisc() }

    func addParticles(_ type: String, _ x: Double, _ y: Double, _ z: Double, _ count: Int, _ spread: Double, _ cell: Int) {
        guard let app, app.game.hasWorld() else { return }
        app.renderer?.particles.spawn(app.game.world, type, x, y, z, count, spread, cell: cell)
    }
    func spawnPrecipitation(_ kind: String, _ x: Double, _ y: Double, _ z: Double, _ groundY: Double) {
        guard let app, app.game.hasWorld() else { return }
        app.renderer?.particles.spawn(app.game.world, kind, x, y, z, 1, 0.1, groundY: groundY)
    }
    func uploadMesh(_ cx: Int, _ sy: Int, _ cz: Int, _ minY: Int, _ mesh: MeshOutput) {
        app?.renderer?.uploadMesh(cx, sy, cz, minY, mesh)
    }
    func removeChunkMeshes(_ cx: Int, _ cz: Int, _ sections: Int) {
        app?.renderer?.removeChunkMeshes(cx, cz, sections)
    }
    func clearAllSections() {
        app?.renderer?.clearAllSections()
    }
}

// pushChat lives in ScreensM at module scope; alias avoids name shadowing here
func Pebble_pushChat(_ line: String) { pushChat(line) }

/// LoadingScreen reads mesh progress off the renderer through this
weak var gAppDelegate: AppDelegate?

// ---------------------------------------------------------------------------
// MTKView with keyboard/mouse capture + screen routing
// ---------------------------------------------------------------------------
final class GameView: MTKView {
    weak var appd: AppDelegate?
    private(set) var mouseCaptured = false

    override var acceptsFirstResponder: Bool { true }

    func captureMouse() {
        if mouseCaptured { return }
        mouseCaptured = true
        CGAssociateMouseAndMouseCursorPosition(0)
        NSCursor.hide()
    }
    func releaseMouse() {
        if !mouseCaptured { return }
        mouseCaptured = false
        CGAssociateMouseAndMouseCursorPosition(1)
        NSCursor.unhide()
    }

    private func nowMs() -> Double { CACurrentMediaTime() * 1000 }
    private var ui: UIManager? { appd?.ui }
    private var game: GameCore? { appd?.game }

    private func uiPos(_ event: NSEvent) -> (Double, Double) {
        // AppKit origin is bottom-left in points; UI space is top-left in
        // drawable pixels / guiScale
        let p = convert(event.locationInWindow, from: nil)
        let bsf = Double(window?.backingScaleFactor ?? 1)
        let scale = ui?.scale ?? 1
        return (Double(p.x) * bsf / scale, (Double(bounds.height) - Double(p.y)) * bsf / scale)
    }

    override func keyDown(with event: NSEvent) {
        guard let game, let ui = ui else { return }
        let code = KEYCODE_MAP[event.keyCode] ?? ""
        // fullscreen toggle works everywhere, including over open screens
        if code == "F11" {
            window?.toggleFullScreen(nil)
            return
        }
        if let screen = ui.current() {
            if event.isARepeat && code != "Backspace" && !code.hasPrefix("Arrow") { return }
            if code == "Escape" {
                if screen.closeOnEsc {
                    ui.closeTop(game)
                    recaptureIfClear()
                }
                return
            }
            if screen.onKey(ui, game, code) { return }
            if let chars = event.characters, !chars.isEmpty, !event.modifierFlags.contains(.command),
               !event.modifierFlags.contains(.control),
               chars.allSatisfy({ !$0.isNewline && $0.asciiValue.map { $0 >= 32 } ?? true }) {
                if screen.onChar(ui, game, chars) { return }
            }
            // inventory key closes inventory-style screens (never text screens)
            if code == game.keybinds["inventory"], screen.closeOnEsc, !(screen is ChatScreen),
               !screen.fields.contains(where: { $0.focused }) {
                ui.closeTop(game)
                recaptureIfClear()
            }
            return
        }
        guard game.hasWorld() else { return }
        if event.isARepeat { return }
        // HUD toggles stay app-side
        if code == "F3" {
            appd?.hud.debugVisible.toggle()
            return
        }
        if code == "F1" {
            appd?.hud.hideGui.toggle()
            return
        }
        game.keyDown(code, now: nowMs(),
                     ctrlOrCmd: event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control))
    }
    override func keyUp(with event: NSEvent) {
        guard let game, let code = KEYCODE_MAP[event.keyCode] else { return }
        game.keyUp(code)
    }
    override func flagsChanged(with event: NSEvent) {
        guard let game, let ui = ui else { return }
        let shift = event.modifierFlags.contains(.shift)
        let ctrl = event.modifierFlags.contains(.control)
        ui.shiftDown = shift
        if ui.hasScreen() {
            // releases must still reach the game — eating them left the
            // player permanently sneaking after shift+E, release, close
            if !shift { game.keyUp("ShiftLeft") }
            if !ctrl { game.keyUp("ControlLeft") }
            return
        }
        // sneak/sprint default binds are modifier keys — synthesize code events
        if shift { game.keyDown("ShiftLeft", now: nowMs()) } else { game.keyUp("ShiftLeft") }
        if ctrl { game.keyDown("ControlLeft", now: nowMs()) } else { game.keyUp("ControlLeft") }
    }

    private func recaptureIfClear() {
        if let ui = ui, !ui.hasScreen(), let game = game, game.hasWorld() {
            captureMouse()
        }
    }

    private func routeMouseDown(_ event: NSEvent, _ btn: Int) {
        guard let game, let ui = ui else { return }
        if let screen = ui.current() {
            let (mx, my) = uiPos(event)
            ui.mouseX = mx
            ui.mouseY = my
            _ = screen.onMouseDown(ui, game, mx, my, btn)
            recaptureIfClear()
            return
        }
        guard game.hasWorld() else { return }
        if !mouseCaptured {
            captureMouse()
            return
        }
        game.mouseDown(btn)
    }

    override func mouseDown(with event: NSEvent) { routeMouseDown(event, 0) }
    override func rightMouseDown(with event: NSEvent) { routeMouseDown(event, 2) }
    override func otherMouseDown(with event: NSEvent) {
        if event.buttonNumber == 2 { routeMouseDown(event, 1) }
    }
    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 { game?.mouseUp(1) }
    }
    override func mouseUp(with event: NSEvent) {
        if let screen = ui?.current(), let game, let ui = ui {
            let (mx, my) = uiPos(event)
            screen.onMouseUp(ui, game, mx, my)
        }
        game?.mouseUp(0)
    }
    override func rightMouseUp(with event: NSEvent) { game?.mouseUp(2) }
    override func mouseDragged(with event: NSEvent) { handleMove(event) }
    override func rightMouseDragged(with event: NSEvent) { handleMove(event) }
    override func mouseMoved(with event: NSEvent) { handleMove(event) }
    private func handleMove(_ event: NSEvent) {
        guard let game, let ui = ui else { return }
        if ui.hasScreen() || !mouseCaptured {
            let (mx, my) = uiPos(event)
            let oldX = ui.mouseX, oldY = ui.mouseY
            _ = (oldX, oldY)
            ui.current()?.onMouseMove(ui, game, mx, my)
            ui.mouseX = mx
            ui.mouseY = my
            return
        }
        game.mouseDelta(Double(event.deltaX), Double(event.deltaY))
    }
    private var scrollAccum = 0.0
    override func scrollWheel(with event: NSEvent) {
        guard let game, let ui = ui else { return }
        var dy = event.scrollingDeltaY
        if event.hasPreciseScrollingDeltas {
            // trackpads deliver many sub-notch deltas — accumulate to a
            // notch instead of discarding them (slow two-finger scrolling
            // did nothing at all)
            scrollAccum += dy
            if abs(scrollAccum) < 8 { return }
            dy = scrollAccum
            scrollAccum = 0
        } else if abs(dy) < 0.5 {
            return
        }
        if let screen = ui.current() {
            _ = screen.onWheel(ui, game, dy > 0 ? -1 : 1)
            return
        }
        if game.hasWorld() {
            game.wheelHotbar(dy > 0 ? 1 : -1)
        }
    }
}

// ---------------------------------------------------------------------------
// app delegate: window, game, renderer, UI, frame loop
// ---------------------------------------------------------------------------
final class AppDelegate: NSObject, NSApplicationDelegate, MTKViewDelegate, NSWindowDelegate {
    private struct Increment07LiveRenderCapture {
        let path: String
        let phase: String
        let target: AgentPosition
        let metadata: String
        let terminateAfterCapture: Bool
        var settleFramesRemaining: Int
    }

    var window: NSWindow!
    var gameView: GameView!
    var renderer: WorldRenderer!
    let host = HostBridge()
    var game: GameCore!
    var ui: UIManager!
    let hud = HUD()
    let agentController = PebbleAgentController()
    let audio = AudioEngineM()
    private var lastFrame = CACurrentMediaTime()
    private var startTime = CACurrentMediaTime()
    private var fpsCounter = 0
    private var fpsTimer = 0.0
    private var fps = 0
    private var uncappedMode = false
    private var uncapTimer: Timer?
    private var persistenceReadyForTermination = false
    private var correction07TerminationAttempt = 0
    private var correction07TerminationCompletionArmed = false
    private var correction08TerminationAttempt = 0
    private var correction08TerminationCompletionArmed = false
    var bot: PhysicsBot?
    var passiveObserverInputProof: PlayableObserverInputProof?
    var booth: PhotoBooth?
    // test hook: PEBBLE_CMD="/tp 0 120 0;/time set 1000" runs once the world is up.
    // A vertical bar starts a second batch after another bounded world-ready delay.
    private var pendingCmds: String? = {
        ProcessInfo.processInfo.environment["PEBBLE_CMD"]?
            .components(separatedBy: "|").first
    }()
    private var pendingCmdBatches: [String] = {
        guard let value = ProcessInfo.processInfo.environment["PEBBLE_CMD"] else { return [] }
        return Array(value.components(separatedBy: "|").dropFirst())
    }()
    private var pendingCmdDelay = 0
    private let passiveObserverBatchFrames: Int? = {
        guard ProcessInfo.processInfo.environment[
            "PEBBLELAB_PASSIVE_OBSERVER_INPUT_PROOF"
        ] == "1", let raw = ProcessInfo.processInfo.environment[
            "PEBBLELAB_PASSIVE_OBSERVER_BATCH_FRAMES"
        ], let value = Int(raw), (240...7200).contains(value) else { return nil }
        return value
    }()
    private let increment03CoverageBatchFrames: Int? = {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PEBBLELAB_PS01_INCREMENT03_LIVE_PROOF"] == "1",
              let raw = environment[
                  "PEBBLELAB_PS01_INCREMENT03_BATCH_FRAMES"
              ], let value = Int(raw), (30...240).contains(value) else {
            return nil
        }
        return value
    }()
    private let gateB3AcceptanceHorizon: Int? = {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PEBBLELAB_GATE_B3_ACCEPTANCE"] == "1",
              let raw = environment["PEBBLELAB_GATE_B3_HORIZON"],
              let value = Int(raw), value > 0 else { return nil }
        return value
    }()
    private let increment05CharacterizationWorldTicks: Int? = {
        let environment = ProcessInfo.processInfo.environment
        guard environment[
            "PEBBLELAB_PS01_INCREMENT05_CHARACTERIZATION"
        ] == "1", let raw = environment[
            "PEBBLELAB_PS01_INCREMENT05_CHARACTERIZATION_WORLD_TICKS"
        ], let value = Int(raw), (1_200...24_000).contains(value) else {
            return nil
        }
        return value
    }()
    private var increment05CharacterizationStartWorldTick: Int?
    private var increment05CharacterizationCompleted = false
    private let increment07LiveCaptureEnabled =
        ProcessInfo.processInfo.environment[
            "PEBBLELAB_PS01_INCREMENT07_LIVE_CAPTURE"
        ] == "1"
    private let increment07LiveCaptureDirectory =
        ProcessInfo.processInfo.environment[
            "PEBBLELAB_PS01_INCREMENT07_LIVE_CAPTURE_DIR"
        ]
    // This coordinate is used only to aim the camera and filter captured trace
    // events. It is never provided to sensing, cognition, pathing, or execution.
    private let increment07LiveObservedSource: AgentPosition? = {
        guard let raw = ProcessInfo.processInfo.environment[
            "PEBBLELAB_PS01_INCREMENT07_LIVE_OBSERVED_SOURCE"
        ] else { return nil }
        let values = raw.split(separator: ",").compactMap { Int($0) }
        guard values.count == 3 else { return nil }
        return AgentPosition(x: values[0], y: values[1], z: values[2])
    }()
    private let increment09LiveEnabled = ProcessInfo.processInfo.environment["PEBBLELAB_PS01_INCREMENT09_LIVE_PHASE"] != nil
    private let increment08LivePhase = ProcessInfo.processInfo.environment["PEBBLELAB_PS01_INCREMENT09_LIVE_PHASE"] ?? ProcessInfo.processInfo.environment["PEBBLELAB_PS01_INCREMENT08_LIVE_PHASE"]
    private let increment08LiveDirectory = ProcessInfo.processInfo.environment["PEBBLELAB_PS01_INCREMENT09_LIVE_CAPTURE_DIR"] ?? ProcessInfo.processInfo.environment["PEBBLELAB_PS01_INCREMENT08_LIVE_CAPTURE_DIR"]
    private var increment08LiveStage = 0
    private var increment08LiveResumeTick = 0
    private var increment08LiveConsumed: UInt64 = 0
    private var increment08LiveCapturePath: String?
    private let occupancyLivePhase = ProcessInfo.processInfo.environment["PEBBLELAB_PS01_OCCUPANCY_LIVE_PHASE"]
    private var occupancyLiveStage = 0
    private var occupancyLiveFrames = 0
    private var occupancyLiveCapturePath: String?
    private var increment07LiveInitialCaptured = false
    private var increment07LiveFirstAttemptID: AgentSubsistenceAttemptID?
    private var increment07LiveRenderCapture: Increment07LiveRenderCapture?
    private var increment07LivePlayerStart: (x: Double, y: Double, z: Double)?
    private var increment07LiveObservedMovement = false
    private let gateB3AcceptanceShock: String? = {
        guard let value = ProcessInfo.processInfo.environment["PEBBLELAB_GATE_B3_SHOCK"],
              !value.isEmpty else { return nil }
        return value
    }()
    private let gateBConvergence =
        ProcessInfo.processInfo.environment["PEBBLELAB_GATE_B_CONVERGENCE"] == "1"
    private let gateB3InterventionTick: Int? = {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PEBBLELAB_GATE_B_CONVERGENCE"] == "1",
              let raw = environment["PEBBLELAB_GATE_B3_INTERVENTION_TICK"],
              let value = Int(raw), value > 0 else { return nil }
        return value
    }()
    private let gateB3SkipCheckpoint =
        ProcessInfo.processInfo.environment["PEBBLELAB_GATE_B3_SKIP_CHECKPOINT"] == "1"
    private let gateB3RandomTickSpeed: Int? = {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PEBBLELAB_GATE_B3_ACCEPTANCE"] == "1",
              let raw = environment["PEBBLELAB_GATE_B3_RANDOM_TICK_SPEED"],
              let value = Int(raw), (1...100).contains(value) else { return nil }
        return value
    }()
    private var gateB3RandomTickApplied = false
    private var gateB3CheckpointAttempted = false
    private var gateB3CheckpointBeforeCustody:
        PebbleGateBConvergenceCustodySnapshot?
    private var gateB3CheckpointAfterCustody:
        PebbleGateBConvergenceCustodySnapshot?
    private var gateB3CheckpointContinuationTarget: Int?
    private var gateB3CheckpointContinuationCaptured = false
    private var gateB3ShockApplied = false
    private var gateB3Completed = false
    private var gateB3CommandCompletionWorldTick: Int?
    private let workDemandRefreshCaptureDirectory =
        ProcessInfo.processInfo.environment["PEBBLELAB_WORK_DEMAND_REFRESH_CAPTURE_DIR"]
    private var workDemandRefreshCapturedMilestones = Set<Int>()
    private let gateB3PassiveSeconds: Double? = {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PEBBLELAB_GATE_B3_PASSIVE"] == "1",
              let raw = environment["PEBBLELAB_GATE_B3_PASSIVE_SECONDS"],
              let value = Double(raw),
              value >= (environment["PEBBLELAB_GATE_B_CONVERGENCE"] == "1"
                  ? 120 : 300) else { return nil }
        return value
    }()
    private let gateB3PassiveCaptureDirectory =
        ProcessInfo.processInfo.environment["PEBBLELAB_GATE_B3_PASSIVE_CAPTURE_DIR"]
    private var gateB3PassiveStartedAt: CFTimeInterval?
    private var gateB3PassiveCapturedMilestones = Set<Int>()
    private var gateB3PassiveCompleted = false
    private var gateB3PassiveMovementStayedEnabled = true
    private var gateB3PassiveInitialCompletions: Int?
    private var gateB3RenderFrame = 0
    private var gateB3FirstCoherentFrame: Int?
    // Persistence proof hook: run command batches at explicit World ticks so a
    // restart and its uninterrupted control cannot inherit renderer-frame timing.
    // The normal PEBBLE_CMD frame delay remains unchanged when this is absent.
    private var pendingCmdWorldTick: Int? = {
        guard ProcessInfo.processInfo.environment["PEBBLELAB_APP_AGENTS_PERSISTENCE"] == "1",
              let value = ProcessInfo.processInfo.environment["PEBBLE_CMD_WORLD_TICK"] else {
            return nil
        }
        return Int(value)
    }()
    // test hook: PEBBLE_SHOT="/tmp/x.png@300" captures after all command batches.
    // A `|`-separated list captures immediately after matching PEBBLE_CMD batches;
    // use `-` to skip a batch. This remains a launch-only reproducibility hook.
    private var shotQuitFrames = 0
    private var pendingCompositedCapturePath: String?
    private var pendingBatchShots: [String] = {
        guard let value = ProcessInfo.processInfo.environment["PEBBLE_SHOT"],
              value.contains("|") else { return [] }
        return value.components(separatedBy: "|")
    }()
    private let usesBatchShots: Bool = {
        ProcessInfo.processInfo.environment["PEBBLE_SHOT"]?.contains("|") == true
    }()
    private var pendingShot: (path: String, frames: Int)? = {
        guard let v = ProcessInfo.processInfo.environment["PEBBLE_SHOT"] else { return nil }
        guard !v.contains("|") else { return nil }
        let parts = v.components(separatedBy: "@")
        return (parts[0], parts.count > 1 ? Int(parts[1]) ?? 240 : 240)
    }()
    private let increment03CoverageLiveProof =
        PebbleIncrement03CoverageLiveProof.fromEnvironment()

    func applicationDidFinishLaunching(_ notification: Notification) {
        gAppDelegate = self
        precondition(disposableWorldProofPauseContractIsValid())
        if suppressAutomaticPauseForDisposableWorldProof() {
            print("[pebblelab-proof] disposable-world gate=armed")
        }
        let t0 = CFAbsoluteTimeGetCurrent()
        game = GameCore()
        game.host = host
        agentController.worldSideReceiptDatabase = game.db
        agentController.installWorldContinuation(on: game)
        game.physicalSimulationCoverageProvider = { [weak agentController] world in
            agentController?.physicalSimulationCoverageRequest(for: world)
                ?? .inactive
        }
        game.prepareExternalLifecycleState = { [weak self] in
            guard let self else { return false }
            guard self.game.hasWorld() else {
                return self.agentController.session == nil
                    && self.agentController.activeWorld == nil
            }
            return self.agentController.prepareForLifecyclePersistence(
                world: self.game.world
            )
        }
        game.finalizeExternalLifecycleState = { [weak self] in
            self?.agentController.finalizeLifecycleAfterPersistence()
        }
        host.app = self
        if occupancyLivePhase != nil {
            prepareOccupancyLiveWorld()
        }
        print(String(format: "registries: %.0fms (%d blocks, %d items, %d biomes)",
                     (CFAbsoluteTimeGetCurrent() - t0) * 1000, blockDefs.count, itemDefs.count, BIOMES.count))

        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("no Metal device") }
        let t1 = CFAbsoluteTimeGetCurrent()
        renderer = WorldRenderer(device: device)
        ui = UIManager(cv: UICanvas(device: device))
        print(String(format: "renderer: %.0fms (atlas + pipelines)", (CFAbsoluteTimeGetCurrent() - t1) * 1000))

        let rect = NSRect(x: 0, y: 0, width: 1440, height: 810)
        window = NSWindow(contentRect: rect, styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Pebble"
        window.center()
        gameView = GameView(frame: rect, device: device)
        gameView.appd = self
        gameView.delegate = self
        gameView.colorPixelFormat = .bgra8Unorm
        gameView.depthStencilPixelFormat = .invalid
        gameView.preferredFramesPerSecond = 120
        // capture hooks blit from the drawable, which framebufferOnly forbids
        let env = ProcessInfo.processInfo.environment
        if env["PEBBLE_SHOT"] != nil || env["PEBBLE_PHOTOBOOTH"] != nil
            || increment07LiveCaptureEnabled || increment08LivePhase != nil || occupancyLivePhase != nil {
            gameView.framebufferOnly = false
        }
        window.contentView = gameView
        window.acceptsMouseMovedEvents = true
        window.delegate = self
        // invisible until the fullscreen transition lands — the user never sees
        // the windowed popup or the zoom animation, just a fade-in (the reveal
        // happens in windowDidEnterFullScreen, or after the retry loop gives up)
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(gameView)
        NSApp.activate(ignoringOtherApps: true)
        // launch straight into fullscreen (F11 toggles back). AppKit silently
        // drops toggleFullScreen during the launch transaction, so retry until
        // the window actually transitions.
        window.collectionBehavior.insert(.fullScreenPrimary)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.enterFullscreenAtLaunch()
        }

        audio.initEngine()
        agentController.physicalAudioAvailable = { [weak audio] in
            audio?.isAvailable ?? false
        }
        audio.applyVolumes(game.settings.volumes)
        audio.onSubtitle = { [weak self] text in
            guard let self, self.game.settings.subtitles else { return }
            self.hud.pushSubtitle(text)
        }

        if increment08LivePhase != nil || occupancyLivePhase != nil {
            // Existing Video Settings option, presentation only. Keep the
            // ordinary debug overlay legible without covering the subject.
            game.settings.guiScale = 2
        }
        ui.resize(Double(gameView.drawableSize.width), Double(gameView.drawableSize.height), game.settings.guiScale)

        // settings.resourcePacks holds USER packs only — the default pack
        // (Faithful base layer) is self-healing and force-applied inside
        // applyResourcePacks, so this always runs, even with no user packs.
        // older settings that listed the default explicitly migrate cleanly
        // (withDefaultPack dedupes it to the base slot).
        applyResourcePacks(game.settings.resourcePacks ?? [], game: game, renderer: renderer, ui: ui)

        ui.titlePhoto = renderer.titleBgTex != nil ; ui.titleLogo = renderer.titleLogoTex != nil
        if occupancyLivePhase == nil { ui.open(TitleScreen(), game) }
        // test hook: jump straight to the world list (UI testing)
        if ProcessInfo.processInfo.environment["PEBBLE_WORLDS"] != nil {
            ui.open(WorldSelectScreen(), game)
        }

        // test hook: skip the menus and jump straight into the latest world.
        // PEBBLE_NEWWORLD=<seed> creates a fresh world instead (worldgen testing)
        if ProcessInfo.processInfo.environment["PEBBLE_AUTOLOAD"] != nil {
            if let seedText = ProcessInfo.processInfo.environment["PEBBLE_NEWWORLD"] {
                let requestedName = ProcessInfo.processInfo.environment["PEBBLE_NEWWORLD_NAME"]
                if let requestedName {
                    precondition(
                        requestedName.hasPrefix("PebbleLab-Disposable-"),
                        "PEBBLE_NEWWORLD_NAME must identify a PebbleLab disposable world"
                    )
                }
                game.createWorld(name: requestedName ?? "WGTest-\(seedText)", seedText: seedText,
                                 mode: GameMode.survival, difficulty: 2)
                if let requestedName {
                    // A named PebbleLab disposable world is a reproducibility fixture, not a normal save.
                    let world = game.world
                    world.randomTickSpeed = 0
                    world.gameRules["doMobSpawning"] = 0
                    world.gameRules["doDaylightCycle"] = 0
                    world.gameRules["doWeatherCycle"] = 0
                    world.dayTime = 1000
                    world.raining = false
                    world.thundering = false
                    world.weatherTimer = 12000
                    print("[lab-live] disposable-world name=\(requestedName) seed=\(world.seed) worldTick=\(world.time) dayTime=\(world.dayTime) weather=clear randomTickSpeed=\(world.randomTickSpeed) mobSpawning=\(Int(world.gameRules["doMobSpawning"] ?? -1))")
                }
            } else if let rec = game.listWorlds().sorted(by: { $0.lastPlayed > $1.lastPlayed }).first {
                game.loadWorld(rec.id)
                if ProcessInfo.processInfo.environment["PEBBLELAB_APP_AGENTS_PERSISTENCE"] == "1",
                   rec.name.hasPrefix("PebbleLab-Disposable-") {
                    // The disposable-world creation hook disables random ticks;
                    // preserve that environment across the real process restart.
                    game.world.randomTickSpeed = 0
                }
            } else {
                game.createWorld(name: "New World", seedText: "", mode: GameMode.survival, difficulty: 2)
            }
            ui.open(LoadingScreen(), game)
            gameView.captureMouse()
            if ProcessInfo.processInfo.environment["PEBBLE_BOT"] != nil {
                bot = PhysicsBot(game: game)
            }
            if ProcessInfo.processInfo.environment[
                "PEBBLELAB_PASSIVE_OBSERVER_INPUT_PROOF"
            ] == "1" {
                passiveObserverInputProof = PlayableObserverInputProof(
                    game: game, controller: agentController
                )
            }
            if ProcessInfo.processInfo.environment["PEBBLE_PHOTOBOOTH"] != nil {
                booth = PhotoBooth(game: game, renderer: renderer)
            }
        }
        if ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C06_TERMINATION_PROOF"
        ] == "1" {
            DispatchQueue.main.async { [weak self] in
                self?.runCorrection06TerminationBoundaryProof()
            }
        }
        if ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C07_TERMINATION_PROOF"
        ] == "1" {
            DispatchQueue.main.async { [weak self] in
                self?.runCorrection07TerminationBoundaryProof()
            }
        }
        if ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C08_PREFX_STREAMING_REPRO"
        ] == "1" {
            DispatchQueue.main.async { [weak self] in
                self?.runCorrection08PreFixStreamingReproduction()
            }
        }
        if ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C08_TERMINATION_PROOF"
        ] == "1" {
            DispatchQueue.main.async { [weak self] in
                self?.runCorrection08TerminationBoundaryProof()
            }
        }
    }

    private func correction08CobblestoneItems(in world: World) -> [ItemEntity] {
        world.entities.compactMap { $0 as? ItemEntity }.filter {
            itemDef($0.stack.id).name == "cobblestone"
        }
    }

    private func correction08CobblestoneQuantity(in world: World) -> Int {
        correction08CobblestoneItems(in: world).reduce(0) {
            $0 + $1.stack.count
        }
    }

    private func runCorrection08TerminationBoundaryProof() {
        guard game.hasWorld() else {
            preconditionFailure("Correction 08 termination proof World unavailable")
        }
        game.settings.renderDistance = 4
        let started = agentController.start(world: game.world, player: game.player)
        guard started.succeeded,
              let agentID = agentController.probesByAgentId.keys.sorted().first,
              let boundProbe = agentController.probesByAgentId[agentID] else {
            preconditionFailure("Correction 08 termination proof civilization unavailable")
        }
        // Structural fail-closed proof for the historical detached-binding
        // shape. Production reproduction uses streaming above; this deliberate
        // mismatch establishes that lifecycle can never again pass vacuously.
        game.world.removeEntity(boundProbe)
        let detachedBindingRefused = !agentController.prepareForLifecyclePersistence(
            world: game.world
        )
        game.world.addEntity(boundProbe)
        guard detachedBindingRefused,
              agentController.probesByAgentId[agentID] === boundProbe,
              game.world.entities.filter({ $0 === boundProbe }).count == 1,
              game.world.entityById[boundProbe.id] === boundProbe,
              let acquisition = try? agentController.acquireStreamingCustodyProofItem(
                  world: game.world,
                  agentID: agentID,
                  itemName: "cobblestone",
                  count: 7,
                  transactionID: "civ45-c08-appkit-streaming-acquisition"
              ) else {
            preconditionFailure("Correction 08 lifecycle binding defense failed")
        }
        let world = game.world
        let probe = acquisition.probe
        let probeEntityID = probe.id
        let probeChunk = world.getChunkAt(Int(floor(probe.x)), Int(floor(probe.z)))
        let playerOrigin = (x: game.player.x, z: game.player.z)
        let simulationID = agentController.session?.simulationID
        let registryIDs = agentController.probesByAgentId.mapValues(\.id)
        agentController.update(
            world: world,
            player: game.player,
            worldID: game.worldRec?.id,
            dimension: world.dim.rawValue
        )
        var streamingExact = true
        for _ in 0..<3 {
            game.player.setPos(
                probe.x + Double((game.settings.renderDistance + 8) * 16),
                game.player.y,
                probe.z
            )
            _ = game.frame(dtMs: TICK_MS)
            streamingExact = streamingExact
                && world.entities.filter({ $0 === probe }).count == 1
                && world.entityById[probeEntityID] === probe
                && agentController.probesByAgentId[agentID] === probe
                && world.getChunkAt(Int(floor(probe.x)), Int(floor(probe.z)))
                    === probeChunk
                && correction08CobblestoneItems(in: world).isEmpty
                && probe.carriedItems[0] == ItemStack(iid("cobblestone"), 7)
            game.player.setPos(playerOrigin.x, game.player.y, playerOrigin.z)
            _ = game.frame(dtMs: TICK_MS)
            streamingExact = streamingExact
                && world.entities.filter({ $0 === probe }).count == 1
                && world.entityById[probeEntityID] === probe
                && agentController.probesByAgentId.mapValues(\.id) == registryIDs
                && probe.carriedItems[0] == ItemStack(iid("cobblestone"), 7)
        }
        game.player.setPos(
            probe.x + Double((game.settings.renderDistance + 8) * 16),
            game.player.y,
            probe.z
        )
        _ = game.frame(dtMs: TICK_MS)
        guard streamingExact,
              world.entities.contains(where: { $0 === probe }),
              agentController.probesByAgentId[agentID] === probe else {
            preconditionFailure("Correction 08 streaming retention failed")
        }

        game.db.testingSignInscriptionPersistenceHook = { $0 != .prepared }
        NSApp.terminate(nil)
        let tickBeforeFirstUpdate = agentController.session?.tick ?? -1
        let firstItems = correction08CobblestoneItems(in: world)
        let firstCoherent = game.hasWorld()
            && agentController.session?.simulationID == simulationID
            && agentController.activeWorld === world
            && agentController.probesByAgentId.mapValues(\.id) == registryIDs
            && world.entities.contains(where: { $0 === probe })
            && probe.carriedItems.allSatisfy { $0 == nil }
            && firstItems.count == 1
            && correction08CobblestoneQuantity(in: world) == 7
        world.time += 20
        agentController.update(
            world: world,
            player: game.player,
            worldID: game.worldRec?.id,
            dimension: world.dim.rawValue
        )
        let firstUpdateContinued = (agentController.session?.tick ?? -1)
            > tickBeforeFirstUpdate

        NSApp.terminate(nil)
        let tickBeforeSecondUpdate = agentController.session?.tick ?? -1
        let secondItems = correction08CobblestoneItems(in: world)
        let secondCoherent = game.hasWorld()
            && agentController.session?.simulationID == simulationID
            && agentController.activeWorld === world
            && agentController.probesByAgentId.mapValues(\.id) == registryIDs
            && world.entities.contains(where: { $0 === probe })
            && probe.carriedItems.allSatisfy { $0 == nil }
            && secondItems.count == 1
            && secondItems.first?.id == firstItems.first?.id
            && correction08CobblestoneQuantity(in: world) == 7
        world.time += 20
        agentController.update(
            world: world,
            player: game.player,
            worldID: game.worldRec?.id,
            dimension: world.dim.rawValue
        )
        let secondUpdateContinued = (agentController.session?.tick ?? -1)
            > tickBeforeSecondUpdate
        let coherent = firstCoherent && firstUpdateContinued
            && secondCoherent && secondUpdateContinued
        print(
            "CIV45_C08_APPKIT_CANCEL firstReply=terminateCancel "
                + "secondReply=terminateCancel session=SAME updates=CONTINUED "
                + "detachedRefusal=PASS "
                + "probeBinding=SAME custody=7 spillEntity=SAME "
                + "duplicateSpill=NO "
                + "status=\(coherent ? "PASS" : "FAIL")"
        )
        fflush(stdout)
        precondition(coherent, "Correction 08 AppKit cancellation coherence failed")
        game.db.testingSignInscriptionPersistenceHook = nil
        correction08TerminationCompletionArmed = true
        NSApp.terminate(nil)
    }

    private func runCorrection08PreFixStreamingReproduction() {
        guard game.hasWorld(), let worldID = game.worldRec?.id else {
            preconditionFailure("Correction 08 pre-fix reproduction World unavailable")
        }
        let started = agentController.start(world: game.world, player: game.player)
        guard started.succeeded,
              let agentID = agentController.probesByAgentId.keys.sorted().first,
              let acquisition = try? agentController.acquireStreamingCustodyProofItem(
                  world: game.world,
                  agentID: agentID,
                  itemName: "cobblestone",
                  count: 7,
                  transactionID: "civ45-c08-prefx-streaming-acquisition"
              ) else {
            preconditionFailure("Correction 08 pre-fix custody acquisition failed")
        }
        let world = game.world
        let probe = acquisition.probe
        let beforeWorld = world.entities.contains(where: { $0 === probe })
        let beforeRegistry = agentController.probesByAgentId[agentID] === probe
        let beforeCarried = probe.carriedItems.compactMap({ $0 }).reduce(0) {
            $0 + (itemDef($1.id).name == "cobblestone" ? $1.count : 0)
        }
        let farDistance = Double((game.settings.renderDistance + 8) * 16)
        game.player.setPos(probe.x + farDistance, game.player.y, probe.z)
        _ = game.frame(dtMs: TICK_MS)
        let afterWorld = world.entities.contains(where: { $0 === probe })
        let afterRegistry = agentController.probesByAgentId[agentID] === probe
        let afterCarried = probe.carriedItems.compactMap({ $0 }).reduce(0) {
            $0 + (itemDef($1.id).name == "cobblestone" ? $1.count : 0)
        }
        print(
            "CIV45_C08_PREFX_STREAMING beforeWorld=\(beforeWorld ? "YES" : "NO") "
                + "beforeRegistry=\(beforeRegistry ? "YES" : "NO") carriedBefore=\(beforeCarried) "
                + "afterWorld=\(afterWorld ? "YES" : "NO") "
                + "afterRegistry=\(afterRegistry ? "YES" : "NO") carriedAfter=\(afterCarried)"
        )
        let exited = game.exitToTitle()
        game.loadWorld(worldID)
        let restartCustody = game.world.entities.compactMap { $0 as? ItemEntity }
            .reduce(0) {
                $0 + (itemDef($1.stack.id).name == "cobblestone" ? $1.stack.count : 0)
            }
        let reproduced = beforeWorld && beforeRegistry && beforeCarried == 7
            && !afterWorld && afterRegistry && afterCarried == 7
            && exited && restartCustody == 0
        print(
            "CIV45_C08_PREFX_EXIT lifecycleBarrier=\(exited ? "PASS" : "FAIL") "
                + "restartCustody=\(restartCustody) expected=0 "
                + "status=\(reproduced ? "REPRODUCED" : "NOT_REPRODUCED")"
        )
        fflush(stdout)
        precondition(reproduced, "Correction 08 pre-fix streaming finding not reproduced")
        NSApp.terminate(nil)
    }

    private func runCorrection07TerminationBoundaryProof() {
        guard game.hasWorld(),
              let chunk = game.world.getChunkAt(
                Int(floor(game.player.x)), Int(floor(game.player.z))
              ) else {
            preconditionFailure("Correction 07 termination proof World unavailable")
        }
        let started = agentController.start(world: game.world, player: game.player)
        guard started.succeeded, agentController.session != nil,
              !agentController.probesByAgentId.isEmpty else {
            preconditionFailure("Correction 07 termination proof civilization unavailable")
        }
        guard let carryingProbe = agentController.probesByAgentId.values.sorted(by: {
            $0.labAgentId < $1.labAgentId
        }).first else {
            preconditionFailure("Correction 07 termination proof probe unavailable")
        }
        carryingProbe.carriedItems[0] = ItemStack(iid("cobblestone"), 2)
        let world = game.world
        let probeIDsBefore = agentController.probesByAgentId.mapValues(\.id)
        let simulationIDBefore = agentController.session?.simulationID
        let focusBefore = agentController.focusedAgentId
        let followModeBefore = agentController.followMode
        let replayWasActive = agentController.replayRecorder != nil
        let sessionBefore = agentController.session != nil
        agentController.update(
            world: world,
            player: game.player,
            worldID: game.worldRec?.id,
            dimension: world.dim.rawValue
        )
        let tickBefore = agentController.session?.tick ?? -1
        chunk.modified = true
        game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
        NSApp.terminate(nil)
        let firstCoherent = game.hasWorld()
            && agentController.session != nil
            && agentController.session?.simulationID == simulationIDBefore
            && agentController.activeWorld === world
            && agentController.probesByAgentId.mapValues(\.id) == probeIDsBefore
            && agentController.focusedAgentId == focusBefore
            && agentController.followMode == followModeBefore
            && carryingProbe.carriedItems.allSatisfy { $0 == nil }
            && world.entities.compactMap { $0 as? ItemEntity }.filter {
                itemDef($0.stack.id).name == "cobblestone"
            }.reduce(0, { $0 + $1.stack.count }) == 2
        world.time += 20
        agentController.update(
            world: world,
            player: game.player,
            worldID: game.worldRec?.id,
            dimension: world.dim.rawValue
        )
        let firstUpdateContinued = (agentController.session?.tick ?? -1) > tickBefore

        NSApp.terminate(nil)
        let secondTickBefore = agentController.session?.tick ?? -1
        let secondCoherent = game.hasWorld()
            && agentController.session != nil
            && agentController.session?.simulationID == simulationIDBefore
            && agentController.activeWorld === world
            && agentController.probesByAgentId.mapValues(\.id) == probeIDsBefore
            && agentController.focusedAgentId == focusBefore
            && agentController.followMode == followModeBefore
            && world.entities.compactMap { $0 as? ItemEntity }.filter {
                itemDef($0.stack.id).name == "cobblestone"
            }.reduce(0, { $0 + $1.stack.count }) == 2
            && (agentController.replayRecorder != nil) == replayWasActive
        world.time += 20
        agentController.update(
            world: world,
            player: game.player,
            worldID: game.worldRec?.id,
            dimension: world.dim.rawValue
        )
        let secondUpdateContinued = (agentController.session?.tick ?? -1) > secondTickBefore
        let coherent = sessionBefore && firstCoherent && firstUpdateContinued
            && secondCoherent && secondUpdateContinued
        print("CIV45_C07_APPKIT_CANCEL firstReply=terminateCancel secondReply=terminateCancel "
            + "WorldRetained=\(game.hasWorld() ? "YES" : "NO") session=present "
            + "updates=CONTINUED duplicateSession=NO duplicateProbe=NO duplicateSpill=NO "
            + "status=\(coherent ? "PASS" : "FAIL")")
        fflush(stdout)
        precondition(coherent, "Correction 07 AppKit cancellation coherence failed")
        game.db.testingSignInscriptionPersistenceHook = nil
        correction07TerminationCompletionArmed = true
        NSApp.terminate(nil)
    }

    private func runCorrection06TerminationBoundaryProof() {
        guard game.hasWorld(), let worldID = game.worldRec?.id,
              let chunk = game.world.getChunkAt(
                Int(floor(game.player.x)),
                Int(floor(game.player.z))
              ) else {
            preconditionFailure("Correction 06 termination proof World unavailable")
        }
        chunk.modified = true
        let key = game.db.chunkKey(worldID, game.world.dim.rawValue, chunk.cx, chunk.cz)
        game.db.testingSignInscriptionPersistenceHook = { phase in phase != .prepared }
        // This invokes AppKit's real termination decision callback. Its first
        // attempt must return to us because persistence failure cancels exit.
        NSApp.terminate(nil)
        let retained = game.hasWorld()
            && game.testingUnresolvedChunkSaveRecord(key: key) != nil
        game.db.testingSignInscriptionPersistenceHook = nil
        let recovered = game.prepareForTermination()
            && game.testingUnresolvedChunkSaveRecord(key: key) == nil
        print("CIV45_C06_APP_TERMINATION firstReply=cancel WorldRetained="
            + "\(retained ? "YES" : "NO") retry=\(recovered ? "COMMITTED" : "FAILED") "
            + "status=\(retained && recovered ? "PASS" : "FAIL")")
        fflush(stdout)
        precondition(retained && recovered, "Correction 06 termination boundary failed")
        NSApp.terminate(nil)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C07_TERMINATION_PROOF"
        ] == "1" {
            correction07TerminationAttempt += 1
        }
        if ProcessInfo.processInfo.environment[
            "PEBBLELAB_CIV45_C08_TERMINATION_PROOF"
        ] == "1" {
            correction08TerminationAttempt += 1
        }
        guard game.prepareForTermination() else {
            persistenceReadyForTermination = false
            print("[lifecycle] application termination refused — active physical state or unresolved persistence retained")
            return .terminateCancel
        }
        precondition(
            game.completePreparedLifecycle(),
            "application termination lifecycle finalization failed"
        )
        if correction07TerminationCompletionArmed {
            let finalState = correction07TerminationAttempt == 3
                && agentController.session == nil
                && agentController.activeWorld == nil
                && agentController.probesByAgentId.isEmpty
            print("CIV45_C07_APPKIT_SUCCESS thirdReply=terminateNow sessionFinal=nil "
                + "probesFinal=0 status=\(finalState ? "PASS" : "FAIL")")
            fflush(stdout)
            precondition(finalState, "Correction 07 AppKit successful termination failed")
        }
        if correction08TerminationCompletionArmed {
            let items = correction08CobblestoneItems(in: game.world)
            let finalState = correction08TerminationAttempt == 3
                && agentController.session == nil
                && agentController.activeWorld == nil
                && agentController.probesByAgentId.isEmpty
                && game.world.entities.compactMap({ $0 as? LabCoreAgentEntity }).isEmpty
                && items.count == 1
                && correction08CobblestoneQuantity(in: game.world) == 7
            print(
                "CIV45_C08_APPKIT_SUCCESS thirdReply=terminateNow sessionFinal=nil "
                    + "probesFinal=0 custody=7 itemEntities=\(items.count) "
                    + "status=\(finalState ? "PASS" : "FAIL")"
            )
            fflush(stdout)
            precondition(finalState, "Correction 08 AppKit successful termination failed")
        }
        persistenceReadyForTermination = true
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard !persistenceReadyForTermination else { return }
        precondition(
            game.prepareForTermination(),
            "application termination reached without durable persistence"
        )
        precondition(
            game.completePreparedLifecycle(),
            "application termination reached without lifecycle finalization"
        )
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// Edit→Paste (Cmd-V): route pasteboard text into the focused screen field
    /// — the UI fields are canvas-drawn, so the standard NSText paste path
    /// never reaches them
    @objc func pasteText(_ sender: Any?) {
        guard let game, let ui, let screen = ui.current(),
              screen.fields.contains(where: { $0.focused }),
              let s = NSPasteboard.general.string(forType: .string) else { return }
        for ch in s where !ch.isNewline && (ch.asciiValue.map { $0 >= 32 } ?? true) {
            _ = screen.onChar(ui, game, String(ch))
        }
    }

    /// AppKit refuses toggleFullScreen while the app is still activating
    /// (windowDidFailToEnterFullScreen fires and the window reverts), so the
    /// launch toggle re-checks until the transition actually completes.
    func windowDidEnterFullScreen(_ notification: Notification) {
        fsEntered = true
        NSAnimationContext.runAnimationGroup {
            $0.duration = 0.3
            window?.animator().alphaValue = 1
        }
    }
    private var fsEntered = false
    private var fsChecks = 0
    private func enterFullscreenAtLaunch() {
        guard let w = window, !fsEntered else { return }
        if fsChecks >= 5 {
            w.alphaValue = 1   // fullscreen never engaged: show windowed, don't stay invisible
            return
        }
        fsChecks += 1
        if !w.styleMask.contains(.fullScreen) { w.toggleFullScreen(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.enterFullscreenAtLaunch()
        }
    }

    /// Cmd-Tab away: release every held key (keyUps go to the other app),
    /// give the system its cursor back (capture sets GLOBAL state that froze
    /// the cursor system-wide), and auto-pause like vanilla.
    func applicationDidResignActive(_ notification: Notification) {
        game?.clearInput()
        gameView?.releaseMouse()
        // Explicit disposable-world proofs must reach their requested World tick
        // when the harness, rather than Pebble, owns focus. PEBBLE_CMD alone
        // remains an ordinary command-injection hook and still auto-pauses.
        guard !suppressAutomaticPauseForDisposableWorldProof() else { return }
        if let game, let ui, game.hasWorld(), !ui.hasScreen() {
            ui.open(PauseScreen(), game)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.resize(Int(size.width), Int(size.height))
        ui.resize(Double(size.width), Double(size.height), game.settings.guiScale, relayout: game)
    }

    /// maxFps >= 250 = unlimited: MTKView's display link can't exceed the panel
    /// refresh, so drive draw() from a runloop timer with vsync off instead
    private func applyFpsMode() {
        let unlimited = game.settings.maxFps >= 250
        if unlimited != uncappedMode {
            uncappedMode = unlimited
            (gameView.layer as? CAMetalLayer)?.displaySyncEnabled = !unlimited
            gameView.isPaused = unlimited
            gameView.enableSetNeedsDisplay = false
            uncapTimer?.invalidate()
            uncapTimer = nil
            if unlimited {
                let t = Timer(timeInterval: 0.0001, repeats: true) { [weak self] _ in
                    self?.gameView.draw()
                }
                RunLoop.main.add(t, forMode: .common)
                uncapTimer = t
            }
        }
        if !unlimited {
            gameView.preferredFramesPerSecond = max(30, game.settings.maxFps)
        }
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        if gateB3PassiveSeconds != nil {
            gateB3RenderFrame += 1
            if game?.hasWorld() == true, gateB3FirstCoherentFrame == nil,
               renderer?.sections.isEmpty == false {
                gateB3FirstCoherentFrame = gateB3RenderFrame
                print(
                    String(
                        format: "[lab-live] GATE_B3_RENDER_COHERENCE "
                            + "firstAnomalousFrame=1 firstCoherentFrame=%d "
                            + "durationFrames=%d durationSeconds=%.3f "
                            + "windowAlpha=%.2f sections=%d",
                        gateB3RenderFrame, max(0, gateB3RenderFrame - 1),
                        now - startTime, window?.alphaValue ?? 0,
                        renderer?.sections.count ?? 0
                    )
                )
            }
        }
        let dt = (now - lastFrame) * 1000
        lastFrame = now
        let timeSec = (now - startTime).truncatingRemainder(dividingBy: 1800)

        fpsTimer += dt
        fpsCounter += 1
        if fpsTimer >= 1000 {
            fps = fpsCounter
            fpsCounter = 0
            fpsTimer -= 1000
            let n = game.harvestMeshCounter()
            hud.debugInfo["fps"] = String(fps)
            hud.debugInfo["chunkUpdates"] = String(n)
            hud.debugInfo["sections"] = String(renderer.sections.count)
            hud.debugInfo["drawCalls"] = String(renderer.drawCalls)
            hud.debugInfo["mem"] = "n/a"
            audio.applyVolumes(game.settings.volumes)
            applyFpsMode()
            if game.hasWorld(), let p = game.player {
                window.title = String(format: "Pebble — %d fps · %d sections · (%.0f, %.0f, %.0f)",
                                      fps, renderer.sections.count, p.x, p.y, p.z)
            } else {
                window.title = "Pebble"
            }
        }

        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let cmd = renderer.queue.makeCommandBuffer() else { return }

        if renderer.fbWidth == 0 {
            renderer.resize(Int(view.drawableSize.width), Int(view.drawableSize.height))
            ui.resize(Double(view.drawableSize.width), Double(view.drawableSize.height), game.settings.guiScale, relayout: game)
        }

        renderer.tickTileAnimations(dtMs: dt)   // resource-pack .mcmeta frames
        renderer.flushAtlasUploads(cmd)         // staged slice blits, GPU-ordered

        if let cmds = pendingCmds, game.hasWorld(), let p = game.player {
            if !gateB3RandomTickApplied, let speed = gateB3RandomTickSpeed {
                gateB3RandomTickApplied = true
                game.world.randomTickSpeed = speed
                print(
                    "[lab-live] GATE_B3_RANDOM_TICKS authority=PebbleCore "
                        + "speed=\(speed) worldTick=\(game.world.time)"
                )
            }
            let commandBatchReady: Bool
            if let targetTick = pendingCmdWorldTick {
                precondition(
                    game.world.time <= targetTick,
                    "PEBBLE_CMD_WORLD_TICK missed: world=\(game.world.time) target=\(targetTick)"
                )
                commandBatchReady = game.world.time == targetTick
            } else {
                pendingCmdDelay += 1
                let requiredFrames = increment03CoverageBatchFrames
                    ?? (agentController.passiveProductProofSnapshot() != nil
                        ? (passiveObserverBatchFrames ?? 240) : 240)
                commandBatchReady = pendingCmdDelay > requiredFrames
            }
            if commandBatchReady {
                if let targetTick = pendingCmdWorldTick {
                    print("[lab-live] command-batch worldTick=\(game.world.time) target=\(targetTick)")
                }
                if p.dead { game.respawnPlayer() }
                for c in cmds.components(separatedBy: ";") where !c.isEmpty {
                    runCommand(game, c.trimmingCharacters(in: .whitespaces))
                }
                increment03CoverageLiveProof?.markCommandBatchExecuted()
                if usesBatchShots, !pendingBatchShots.isEmpty {
                    let shot = pendingBatchShots.removeFirst()
                    if shot != "-", !shot.isEmpty {
                        pendingCompositedCapturePath = shot
                    }
                }
                if pendingCmdBatches.isEmpty {
                    pendingCmds = nil
                    if gateB3AcceptanceHorizon != nil {
                        gateB3CommandCompletionWorldTick = game.world.time
                    }
                    if usesBatchShots {
                        shotQuitFrames = ProcessInfo.processInfo.environment[
                            "PEBBLELAB_INTEGRATED_TEACHING_PROOF"
                        ] == "1" ? 20 : 120
                    }
                } else {
                    pendingCmds = pendingCmdBatches.removeFirst()
                    pendingCmdDelay = 0
                    if pendingCmdWorldTick != nil {
                        pendingCmdWorldTick = game.world.time + 1
                    }
                }
            }
        }
        if let shot = pendingShot, game.hasWorld(), pendingCmds == nil {
            hud.hideGui = true
            pendingShot = (shot.path, shot.frames - 1)
            if shot.frames <= 0 {
                pendingCompositedCapturePath = shot.path
                pendingShot = nil
                hud.hideGui = false
                // scripted-shot runs quit on their own — leave a beat for the
                // final UI-composited window capture to land before terminating
                shotQuitFrames = 120
            }
        }
        if shotQuitFrames > 0 {
            shotQuitFrames -= 1
            if shotQuitFrames == 0 { NSApp.terminate(nil) }
        }

        let enc: MTLRenderCommandEncoder
        if game.hasWorld() {
            // Cap only the explicit persistence-proof scheduler below one
            // simulation step so its requested World tick cannot be skipped.
            // Once its final batch has run, freeze World age until the scripted
            // shutdown so the saved continuation boundary is byte-reproducible.
            let frameDelta: Double
            if occupancyLivePhase != nil || increment08LiveStage == 1 || increment08LiveStage == 3 {
                frameDelta = 0
            } else if pendingCmdWorldTick == nil {
                frameDelta = dt
            } else if pendingCmds == nil {
                frameDelta = 0
            } else {
                frameDelta = min(dt, 10)
            }
            passiveObserverInputProof?.beforeFrame()
            let framePartial = game.frame(dtMs: frameDelta)
            let partial = occupancyLivePhase == nil ? framePartial : 1
            driveIncrement07LiveCaptureBeforeCognition()
            if occupancyLivePhase == nil { agentController.update(
                world: game.world,
                player: game.player,
                worldID: game.worldRec?.id,
                dimension: game.dim.rawValue,
                maximumSimulationTick: gateB3AcceptanceHorizon
            ) }
            driveIncrement07LiveCaptureAfterCognition()
            driveIncrement08LiveContinuation()
            driveOccupancyLiveCapture()
            driveIncrement05NaturalCharacterization()
            if let evidence = increment03CoverageLiveProof?.afterFrame(
                game: game,
                controller: agentController,
                frameMilliseconds: dt,
                framesPerSecond: fps
            ) {
                print(evidence)
            }
            driveGateB3Acceptance()
            passiveObserverInputProof?.afterFrame()
            driveGateB3Passive(now: now)
            renderer.pebbleAgentPhysicalGestures = agentController.physicalGestureMarkers()
            bot?.tick()
            booth?.tickBooth()
            renderer.particles.tick(game.world)
            let baseCamera = game.camState(partial, timeSec: timeSec)
            let cam = increment07LiveRenderCamera(overriding: baseCamera)
            enc = renderer.render(cmd: cmd, rpd: rpd, game: game, cam: cam, partial: partial, timeSec: timeSec)
        } else {
            agentController.update(world: nil, player: nil)
            renderer.pebbleAgentPhysicalGestures = []
            enc = renderer.renderTitle(cmd: cmd, rpd: rpd)
        }

        // ---- UI pass ----
        ui.beginFrame()
        let screen = ui.current()
        if game.hasWorld() && (screen == nil || screen!.showHUD || !screen!.pausesGame) {
            hud.draw(ui, game, 0)
            if !(screen is ChatScreen) { drawChatOverlay(ui) }
            if !hud.hideGui,
               let observer = agentController.observerPresentation(world: game.world) {
                hud.drawPebbleObserver(ui, observer)
            } else if !hud.hideGui,
                      let state = agentController.debugState(f3Visible: hud.debugVisible) {
                hud.drawPebbleAgentOverlay(ui, state)
            }
        }
        screen?.draw(ui, game, 0)
        ui.endFrame()
        ui.cv.flush(enc, pipeline: renderer.uiPipeline)

        enc.endEncoding()
        if let capturePath = pendingCompositedCapturePath {
            pendingCompositedCapturePath = nil
            encodeCompositedCapture(cmd, from: drawable.texture, to: capturePath)
        }
        cmd.present(drawable)
        cmd.commit()
    }

    private func driveGateB3Acceptance() {
        guard !gateB3Completed, let horizon = gateB3AcceptanceHorizon else { return }
        guard let proof = agentController.passiveProductProofSnapshot() else {
            if let completedAt = gateB3CommandCompletionWorldTick,
               game.world.time - completedAt >= 40 {
                gateB3Completed = true
                agentController.traceGateB3AcceptanceSnapshot(world: game.world)
                print(
                    "[lab-live] GATE_B3_FATAL_INVARIANT seed=\(game.world.seed) "
                        + "tick=0 runtimeErrors=0 horizon=\(horizon) "
                        + "reason=bootstrap_contract_failed"
                )
                fflush(stdout)
                NSApp.terminate(nil)
            }
            return
        }
        captureWorkDemandRefreshMilestone(proof)
        if gateBConvergence, !gateB3CheckpointContinuationCaptured,
           let target = gateB3CheckpointContinuationTarget,
           proof.simulationTick >= target {
            gateB3CheckpointContinuationCaptured = true
            let continued = agentController.traceGateBConvergenceCustody(
                phase: "continued",
                world: game.world
            )
            let before = gateB3CheckpointBeforeCustody
            let after = gateB3CheckpointAfterCustody
            print(
                "[lab-live] GATE_B_CONVERGENCE_CHECKPOINT_CONTINUED "
                    + "targetTick=\(target) actualTick=\(proof.simulationTick) "
                    + "snapshotPresent=\(continued == nil ? 0 : 1) "
                    + "stableCivilizationIDs="
                    + "\((before?.civilizationAgentIDs == continued?.civilizationAgentIDs) ? 1 : 0) "
                    + "postLoadCustodyDigest="
                    + "\(after?.trackedCustodyDigest ?? "missing") "
                    + "continuedCustodyDigest="
                    + "\(continued?.trackedCustodyDigest ?? "missing") "
                    + "postLoadMaterialTotals="
                    + "\(after?.materialTotals ?? "missing") "
                    + "continuedMaterialTotals="
                    + "\(continued?.materialTotals ?? "missing")"
            )
        }
        if proof.runtimeErrors > 0 {
            gateB3Completed = true
            agentController.traceGateB3AcceptanceSnapshot(world: game.world)
            print(
                "[lab-live] GATE_B3_FATAL_INVARIANT seed=\(game.world.seed) "
                    + "tick=\(proof.simulationTick) runtimeErrors=\(proof.runtimeErrors) "
                    + "worldTick=\(game.world.time) horizon=\(horizon) "
                    + "reason=cognitive_transition_failed"
            )
            fflush(stdout)
            NSApp.terminate(nil)
            return
        }
        let boundary = horizon / 2
        if game.world.seed == 887, !gateB3SkipCheckpoint, !gateB3CheckpointAttempted,
           proof.simulationTick >= boundary {
            gateB3CheckpointAttempted = true
            let convergenceBefore = try? agentController
                .gateBConvergenceSemanticSnapshot(world: game.world)
            let custodyBefore = agentController.traceGateBConvergenceCustody(
                phase: "before",
                world: game.world
            )
            gateB3CheckpointBeforeCustody = custodyBefore
            print(
                "[lab-live] GATE_B3_CHECKPOINT_BOUNDARY seed=887 "
                    + "tick=\(proof.simulationTick) target=\(boundary)"
            )
            runCommand(game, "/lab pause")
            let saveResult = agentController.handleCheckpoint(
                ["save", "gate-b3-887-mid"],
                world: game.world
            )
            let loadResult: PebbleAgentCommandResult
            if saveResult.succeeded {
                loadResult = agentController.handleCheckpoint(
                    ["load", "gate-b3-887-mid"],
                    world: game.world
                )
            } else {
                loadResult = PebbleAgentCommandResult(
                    succeeded: false,
                    message: "load not attempted because checkpoint save failed"
                )
            }
            runCommand(game, "/lab resume")
            if gateBConvergence {
                let convergenceAfter = try? agentController
                    .gateBConvergenceSemanticSnapshot(world: game.world)
                let custodyAfter = agentController.traceGateBConvergenceCustody(
                    phase: "after",
                    world: game.world
                )
                gateB3CheckpointAfterCustody = custodyAfter
                if loadResult.succeeded {
                    gateB3CheckpointContinuationTarget = proof.simulationTick + 4
                }
                let exact = convergenceBefore != nil
                    && convergenceAfter != nil
                    && convergenceBefore == convergenceAfter
                let custodyExact = custodyBefore != nil
                    && custodyAfter != nil
                    && custodyBefore == custodyAfter
                let configurationUnchanged = convergenceBefore != nil
                    && convergenceAfter != nil
                    && convergenceBefore?.durable == convergenceAfter?.durable
                let reconciled = agentController.liveBindingsReconciled(
                    world: game.world
                )
                print(
                    "[lab-live] GATE_B_CONVERGENCE_CHECKPOINT "
                        + "saveSucceeded=\(saveResult.succeeded ? 1 : 0) "
                        + "loadSucceeded=\(loadResult.succeeded ? 1 : 0) "
                        + "exact=\(exact ? 1 : 0) "
                        + "custodyExact=\(custodyExact ? 1 : 0) "
                        + "beforeTick=\(convergenceBefore?.tick ?? -1) "
                        + "afterTick=\(convergenceAfter?.tick ?? -1) "
                        + "beforeDurable=\(convergenceBefore?.durable ?? "missing") "
                        + "afterDurable=\(convergenceAfter?.durable ?? "missing") "
                        + "beforeSemantic="
                        + "\(convergenceBefore?.semanticDigest ?? "missing") "
                        + "afterSemantic="
                        + "\(convergenceAfter?.semanticDigest ?? "missing") "
                        + "configurationUnchanged="
                        + "\(configurationUnchanged ? 1 : 0) "
                        + "reconciled=\(reconciled ? 1 : 0) "
                        + "beforeMaterialTotals="
                        + "\(custodyBefore?.materialTotals ?? "missing") "
                        + "afterMaterialTotals="
                        + "\(custodyAfter?.materialTotals ?? "missing") "
                        + "beforeAgentQuantity="
                        + "\(custodyBefore?.agentMaterialQuantity ?? -1) "
                        + "afterAgentQuantity="
                        + "\(custodyAfter?.agentMaterialQuantity ?? -1) "
                        + "beforeContainerQuantity="
                        + "\(custodyBefore?.containerMaterialQuantity ?? -1) "
                        + "afterContainerQuantity="
                        + "\(custodyAfter?.containerMaterialQuantity ?? -1) "
                        + "beforeLooseQuantity="
                        + "\(custodyBefore?.looseMaterialQuantity ?? -1) "
                        + "afterLooseQuantity="
                        + "\(custodyAfter?.looseMaterialQuantity ?? -1) "
                        + "beforeTotalQuantity="
                        + "\(custodyBefore?.totalMaterialQuantity ?? -1) "
                        + "afterTotalQuantity="
                        + "\(custodyAfter?.totalMaterialQuantity ?? -1) "
                        + "beforeCompletions="
                        + "\(convergenceBefore?.completions ?? -1) "
                        + "afterCompletions="
                        + "\(convergenceAfter?.completions ?? -1)"
                )
            }
        }
        let shockBoundary = gateB3InterventionTick ?? boundary
        if let shock = gateB3AcceptanceShock, !gateB3ShockApplied,
           proof.simulationTick >= shockBoundary {
            gateB3ShockApplied = true
            if shock == "material-reactivation-berry" {
                agentController.traceGateB3AcceptanceSnapshot(world: game.world)
            }
            agentController.applyGateB3AcceptanceShock(shock, world: game.world)
        }
        guard let updated = agentController.passiveProductProofSnapshot(),
              updated.simulationTick >= horizon else { return }
        gateB3Completed = true
        agentController.traceGateB3AcceptanceSnapshot(world: game.world)
        if gateBConvergence {
            agentController.traceGateBConvergenceEvidence(world: game.world)
        }
        print(
            "[lab-live] GATE_B3_HORIZON_COMPLETE seed=\(game.world.seed) "
                + "tick=\(updated.simulationTick) target=\(horizon) "
                + "exact=\(updated.simulationTick == horizon ? 1 : 0)"
        )
        fflush(stdout)
        NSApp.terminate(nil)
    }

    private func driveIncrement05NaturalCharacterization() {
        guard !increment05CharacterizationCompleted,
              let duration = increment05CharacterizationWorldTicks,
              agentController.session != nil else { return }
        guard let start = increment05CharacterizationStartWorldTick else {
            increment05CharacterizationStartWorldTick = game.world.time
            print(
                "[lab-live] PS01_INCREMENT_05_NATURAL_START "
                    + "seed=\(game.world.seed) worldTick=\(game.world.time) "
                    + "targetWorldTicks=\(duration) cognitionHz="
                    + "\(agentController.cognitiveHz)"
            )
            return
        }
        guard game.world.time - start >= duration else { return }
        increment05CharacterizationCompleted = true
        let traced = agentController.traceIncrement05NaturalCharacterization(
            world: game.world,
            startWorldTick: start
        )
        print(
            "[lab-live] PS01_INCREMENT_05_NATURAL_COMPLETE "
                + "seed=\(game.world.seed) traced=\(traced ? 1 : 0)"
        )
        fflush(stdout)
        NSApp.terminate(nil)
    }

    private func driveIncrement07LiveCaptureBeforeCognition() {
        guard increment07LiveCaptureEnabled,
              let target = increment07LiveObservedSource,
              let directory = increment07LiveCaptureDirectory,
              game.hasWorld(), agentController.session != nil else { return }
        if increment07LivePlayerStart == nil {
            let player = game.player!
            increment07LivePlayerStart = (player.x, player.y, player.z)
            print(
                String(
                    format: "[lab-live] PS01_INCREMENT_07_PLAYER_BOUNDARY phase=start "
                        + "worldTick=%d civilizationTick=%d position=%.6f,%.6f,%.6f "
                        + "movementInput=none harnessPlayerMutation=none",
                    game.world.time, agentController.session?.tick ?? -1,
                    player.x, player.y, player.z
                )
            )
            fflush(stdout)
        }
        let source = game.world.getBlock(target.x, target.y, target.z)
        if !increment07LiveInitialCaptured,
           source >> 4 == Int(B.sweet_berry_bush), source & 15 >= 2 {
            increment07LiveInitialCaptured = true
            scheduleIncrement07LiveCapture(
                path: directory + "/01-initial-source.png",
                phase: "preHarvest",
                target: target,
                metadata: "worldTick=\(game.world.time) "
                    + "civilizationTick=\(agentController.session?.tick ?? -1) "
                    + "sourceStage=\(source & 15)",
                terminateAfterCapture: false
            )
            print(
                "[lab-live] PS01_INCREMENT_07_INITIAL_SOURCE seed="
                    + "\(game.world.seed) worldTick=\(game.world.time) target="
                    + "\(target.x),\(target.y),\(target.z) stage=\(source & 15) "
                    + "normalFounders=24 captureFilterOnly=1 "
                    + "cameraAuthority=renderOnlyObserver"
            )
            fflush(stdout)
        }
    }

    private func driveIncrement07LiveCaptureAfterCognition() {
        guard increment07LiveCaptureEnabled,
              let target = increment07LiveObservedSource,
              let directory = increment07LiveCaptureDirectory,
              game.hasWorld(), let session = agentController.session else { return }
        if agentController.lastMovementOutcomes.contains(where: { $0.status == .moved }) {
            increment07LiveObservedMovement = true
        }
        let retained = session.wildSubsistenceSnapshot().retainedOutcomes
        let outcomes: [AgentSubsistenceOutcome] = retained.compactMap { record in
            let outcome = record.outcome
            guard outcome.status == .succeeded,
                  outcome.targetPosition == target,
                  outcome.attribution
                    == "core-canonical-preserving-sweet-berry-harvest" else {
                return nil
            }
            return outcome
        }
        if increment07LiveFirstAttemptID == nil, let first = outcomes.first {
            increment07LiveFirstAttemptID = first.attemptID
            let source = game.world.getBlock(target.x, target.y, target.z)
            let totalAcquired = retained.map(\.outcome).reduce(0) { total, outcome in
                total + outcome.acquiredItems.filter {
                    $0.identity.itemKey == "sweet_berries"
                }.reduce(0) { $0 + $1.count }
            }
            let totalCarried = agentController.probesByAgentId.values.reduce(0) {
                total, probe in
                total + probe.carriedItems.compactMap { $0 }.reduce(0) {
                    $0 + (itemName($1.id) == "sweet_berries" ? $1.count : 0)
                }
            }
            let totalConsumed = session.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity ?? 0
            let conservation = totalAcquired == totalCarried + Int(totalConsumed)
                ? "exact" : "diverged"
            let custody = first.custodyFingerprint?.isEmpty == false
                && !first.physicalCausalIDs.isEmpty ? "verified" : "missing"
            let player = game.player!
            let playerStart = increment07LivePlayerStart
                ?? (player.x, player.y, player.z)
            let playerUnchanged = player.x == playerStart.x
                && player.y == playerStart.y
                && player.z == playerStart.z
            scheduleIncrement07LiveCapture(
                path: directory + "/02-after-first-acquisition.png",
                phase: "postFirstAcquisition",
                target: target,
                metadata: "worldTick=\(game.world.time) "
                    + "civilizationTick=\(first.completedAtTick) "
                    + "sourceStage=\(source & 15) actor=\(first.actorID.rawValue) "
                    + "quantity=\(first.acquiredQuantity) custody=\(custody)",
                terminateAfterCapture: true
            )
            let fields = [
                "[lab-live] PS01_INCREMENT_07_FIRST_ACQUISITION",
                "seed=\(game.world.seed)",
                "worldTick=\(game.world.time)",
                "civilizationTick=\(first.completedAtTick)",
                "actor=\(first.actorID.rawValue)",
                "target=\(target.x),\(target.y),\(target.z)",
                "quantity=\(first.acquiredQuantity)",
                "sourceStage=\(source & 15)",
                "custody=\(custody)",
                "physicalCausalIDs=\(first.physicalCausalIDs.map(String.init).joined(separator: ","))",
                "acquiredTotal=\(totalAcquired)",
                "consumedTotal=\(totalConsumed)",
                "carriedTotal=\(totalCarried)",
                "conservation=\(conservation)",
                "founders=\(agentController.probesByAgentId.count)",
                "movementObserved=\(increment07LiveObservedMovement ? 1 : 0)",
                "runtimeErrors=\(agentController.runtimeErrorCount)",
                "catchUpDrops=\(agentController.droppedCatchUpSteps)",
                "fatalIntegrity=\(agentController.fatalSessionIntegrityFailure == nil ? 0 : 1)",
                String(
                    format: "playerStart=%.6f,%.6f,%.6f",
                    playerStart.x, playerStart.y, playerStart.z
                ),
                String(
                    format: "playerEnd=%.6f,%.6f,%.6f",
                    player.x, player.y, player.z
                ),
                "playerUnchanged=\(playerUnchanged ? 1 : 0)",
                "harnessPlayerMutation=none",
                "cameraAuthority=renderOnlyObserver",
            ]
            print(fields.joined(separator: " "))
            fflush(stdout)
        }
    }

    /// Launch-gated visual evidence; saves and restores remain ordinary product
    /// callbacks. Camera changes are render-only and never move the Player.
    private func increment08LiveTerrainReady(around target: AgentPosition) -> Bool {
        // LoadingScreen has a timeout, and physical chunk readiness does not
        // imply that asynchronous lighting/meshing has reached the renderer.
        // Observe existing GPU uploads around the subject; never force a mesh
        // or advance a separate rendering/simulation owner.
        let cx = target.x >> 4, cz = target.z >> 4
        for dz in -1...1 {
            for dx in -1...1 {
                guard let chunk = game.world.getChunk(cx + dx, cz + dz), chunk.status == .lit else { return false }
                let surfaceY = Int(chunk.heightmap[8 * 16 + 8])
                let sy = (surfaceY - chunk.minY) >> 4
                guard renderer.sections[SectionKey(cx: cx + dx, sy: sy, cz: cz + dz)]?.opaque != nil else { return false }
            }
        }
        let sy = (target.y - 1 - game.world.info.minY) >> 4
        return renderer.sections[SectionKey(cx: cx, sy: sy, cz: cz)]?.opaque != nil
    }

    private func driveIncrement08LiveContinuation() {
        guard let phase = increment08LivePhase, let directory = increment08LiveDirectory,
              ["write", "read", "resave", "observe"].contains(phase), increment08LiveStage < 4,
              let session = agentController.session else { return }
        guard !(ui.current() is LoadingScreen) else { return }
        precondition(game.worldContinuationReady && agentController.runtimeErrorCount == 0
            && agentController.fatalSessionIntegrityFailure == nil, "I08 live integrity")
        let consumed = session.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity ?? 0
        let incrementLabel = increment09LiveEnabled ? "09" : "08"
        let birth = session.birthsSnapshot().first
        if increment09LiveEnabled, birth == nil { return }
        let carrying = agentController.probesByAgentId.values.filter {
            $0.carriedItems.compactMap { $0 }.contains { itemName($0.id) == "sweet_berries" }
        }.sorted { $0.labAgentId < $1.labAgentId }
        guard let target = (increment09LiveEnabled ? birth.flatMap { agentController.probesByAgentId[$0.newbornID.rawValue] } : carrying.first) ?? agentController.probesByAgentId.values.sorted(by: { $0.labAgentId < $1.labAgentId }).first else { return }
        let position = AgentPosition(x: Int(target.x.rounded(.down)), y: Int(target.y.rounded(.down)), z: Int(target.z.rounded(.down)))
        func capture(_ name: String) {
            let cx = position.x >> 4, cz = position.z >> 4
            let sy = (position.y - 1 - game.world.info.minY) >> 4
            let terrain = renderer.sections[SectionKey(cx: cx, sy: sy, cz: cz)]
            let neighborStates = [(-1, 0), (1, 0), (0, -1), (0, 1)].map {
                game.world.getChunk(cx + $0.0, cz + $0.1).map { String(describing: $0.status) } ?? "absent"
            }.joined(separator: ",")
            print("[lab-live] PS01_INCREMENT_\(incrementLabel)_RENDER_READY phase=\(name) worldTick=\(game.world.time) target=\(position.x),\(position.y),\(position.z) chunkStatus=\(game.world.getChunk(cx, cz).map { String(describing: $0.status) } ?? "absent") neighbors=\(neighborStates) sections=\(renderer.sections.count) targetOpaque=\(terrain?.opaque?.indexCount ?? 0) targetCutout=\(terrain?.cutout?.indexCount ?? 0) targetTranslucent=\(terrain?.translucent?.indexCount ?? 0) surfaceNeighborhood=9 loadingScreen=0")
            let path = directory + "/" + name + ".png"
            increment08LiveCapturePath = path
            scheduleIncrement07LiveCapture(path: path, phase: "i" + incrementLabel + "-" + name, target: position,
                metadata: "increment=\(incrementLabel) newborn=\(birth?.newbornID.rawValue ?? "none") births=\(session.birthsSnapshot().count) living=\(session.snapshot().agents.count) worldTick=\(game.world.time) civilizationTick=\(session.tick) consumed=\(consumed) carryingAgents=\(carrying.count)", terminateAfterCapture: false)
            print("[lab-live] PS01_INCREMENT_\(incrementLabel)_CAPTURE_REQUEST phase=\(name) world=\(game.worldRec!.id) simulation=\(session.simulationID.rawValue) tick=\(session.tick) consumed=\(consumed) carryingAgents=\(carrying.count) newborn=\(birth?.newbornID.rawValue ?? "none") births=\(session.birthsSnapshot().count) cameraAuthority=renderOnlyObserver path=\(path)")
            fflush(stdout)
        }
        if increment08LiveStage == 0 {
            guard pendingCmds == nil, increment08LiveTerrainReady(around: position) else { return }
            if !increment09LiveEnabled {
                if (phase == "write" || phase == "resave") && carrying.isEmpty { return }
                precondition(session.snapshot().agents.count == 24, "I08 live founder envelope")
            } else {
                precondition(session.normalPhysicalReproductionEnabled && birth != nil,
                             "I09 native birth authority")
                precondition(game.world.entities.compactMap { ($0 as? LabCoreAgentEntity)?.labAgentId }.sorted()
                    == session.expectedActiveAgentIDs().map(\.rawValue).sorted(), "I09 exact bodies")
            }
            capture(phase == "write" || phase == "resave" ? "before-save" : "after-restore")
            increment08LiveStage = 1
            increment08LiveConsumed = consumed
            return
        }
        if increment08LiveStage == 1 || increment08LiveStage == 3 {
            guard let path = increment08LiveCapturePath, FileManager.default.fileExists(atPath: path) else { return }
            if (phase == "read" || phase == "observe") && increment08LiveStage == 1 {
                increment08LiveResumeTick = game.world.time
                increment08LiveStage = 2
                return
            }
            increment08LiveStage = 4
            let digest = try! session.durableStateDigest().rawValue
            let tick = session.tick
            let material = agentController.probesByAgentId.values.reduce(0) { total, probe in
                total + probe.carriedItems.compactMap { $0 }.reduce(0) { $0 + $1.count }
            }
            precondition(increment09LiveEnabled || phase != "read" || consumed > increment08LiveConsumed, "I08 live restored food remains usable")
            precondition(session.wildSubsistenceEnabled && session.physicalFoodSurvivalEnabled,
                "I08 live ordinary subsistence remains enabled")
            if increment09LiveEnabled {
                try! session.durableStateBytes().write(to: URL(fileURLWithPath: directory + "/" + phase + ".session.json"), options: .atomic)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                precondition(self.game.saveAndFlush(), "I08 live Save/Continue")
                precondition((try! self.agentController.session!.durableStateDigest().rawValue) == digest, "I08 live capture changes civilization")
                precondition(self.game.exitToTitle(), "I08 live Save/Exit")
                precondition(self.agentController.session == nil && self.agentController.probesByAgentId.isEmpty, "I08 live lifecycle cleanup")
                print("[lab-live] PS01_INCREMENT_\(incrementLabel)_LIVE_PASS phase=\(phase) tick=\(tick) digest=\(digest) carried=\(material) consumed=\(consumed) foundersCreated=\(phase == "write" ? 24 : 0) subsistenceEnabled=1 saveContinue=PASS saveExit=PASS probesFinal=0")
                fflush(stdout)
                NSApp.terminate(nil)
            }
            return
        }
        if increment08LiveStage == 2 && game.world.time - increment08LiveResumeTick >= 1200
            && increment08LiveTerrainReady(around: position)
            && (increment09LiveEnabled || phase != "read" || consumed > increment08LiveConsumed) {
            capture("continued")
            increment08LiveStage = 3
        }
    }

    /// This gated proof uses this app's actual GameCore/controller and later
    /// its normal Metal renderer. Natural stepping precedes UI attachment so
    /// menus, input and frame timing cannot alter the matched save boundary.
    private func prepareOccupancyLiveWorld() {
        let env = ProcessInfo.processInfo.environment
        do {
            guard let phase = occupancyLivePhase, ["write", "read"].contains(phase),
                  let home = env["CFFIXED_USER_HOME"],
                  home.hasPrefix("/tmp/") || home.hasPrefix("/private/tmp/"),
                  let output = env["PEBBLELAB_PS01_OCCUPANCY_OUTPUT"],
                  env["PEBBLELAB_PS01_OCCUPANCY_LIVE_CAPTURE_DIR"] != nil else {
                throw PebbleContinuationEmbodimentQualification.Failure.refused("isolated native proof configuration required")
            }
            game.host = nil
            if phase == "write" {
                try PebbleContinuationEmbodimentQualification.prepareWriter(game, agentController)
                _ = try PebbleContinuationEmbodimentQualification.boundary(game, agentController)
            } else {
                PebbleContinuationEmbodimentQualification.configure(game, agentController)
                let expected = try JSONDecoder().decode(OccupancyQualificationBoundary.self,
                    from: Data(contentsOf: URL(fileURLWithPath: output)))
                game.loadWorld(expected.worldID)
                try PebbleContinuationEmbodimentQualification.verifyReader(game, agentController, expected: expected)
            }
            game.host = host
            game.perspective = 1 // existing presentation option: render Player
            print("[lab-live] PS01_OCCUPANCY_NATIVE_READY phase=\(phase) world=\(game.world.time) agents=\(agentController.probesByAgentId.count) playerMutation=none entityMutation=none"); fflush(stdout)
        } catch {
            fputs("[lab-live] PS01_OCCUPANCY_NATIVE_FAIL \(error)\n", stderr)
            exit(1)
        }
    }

    private func driveOccupancyLiveCapture() {
        guard let phase = occupancyLivePhase, occupancyLiveStage < 4 else { return }
        occupancyLiveFrames += 1
        precondition(occupancyLiveFrames <= 2400, "bounded occupancy native rendering")
        let env = ProcessInfo.processInfo.environment
        if occupancyLiveStage == 0 {
            guard let target = agentController.session?.snapshot().agents.first(where: { $0.id == "agent_1" }),
                  increment08LiveTerrainReady(around: target.position) else { return }
            let path = env["PEBBLELAB_PS01_OCCUPANCY_LIVE_CAPTURE_DIR"]! + "/" + phase + ".png"
            occupancyLiveCapturePath = path
            scheduleIncrement07LiveCapture(path: path, phase: "occupancy-" + phase,
                target: target.position,
                metadata: "worldTick=\(game.world.time) living=24 player=present spider=present probeAuthority=Session",
                terminateAfterCapture: false)
            occupancyLiveStage = 1
            return
        }
        if occupancyLiveStage == 3, let path = occupancyLiveCapturePath,
           FileManager.default.fileExists(atPath: path) {
            occupancyLiveStage = 4
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                do {
                    try PebbleContinuationEmbodimentQualification.finishWriter(self.game, self.agentController,
                        output: env["PEBBLELAB_PS01_OCCUPANCY_OUTPUT"]!, alreadyContinued: true)
                    print("[lab-live] PS01_OCCUPANCY_NATIVE_PASS phase=write actualMetalCapture=write.png,continue.png saveContinue=PASS saveExit=PASS"); fflush(stdout)
                    NSApp.terminate(nil)
                } catch { fputs("[lab-live] PS01_OCCUPANCY_NATIVE_FAIL \(error)\n", stderr); exit(1) }
            }
            return
        }
        guard occupancyLiveStage == 1, let path = occupancyLiveCapturePath,
              FileManager.default.fileExists(atPath: path) else { return }
        occupancyLiveStage = 2
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                let output = env["PEBBLELAB_PS01_OCCUPANCY_OUTPUT"]!
                if phase == "write" {
                    try PebbleContinuationEmbodimentQualification.saveContinueWriter(self.game, self.agentController, output: output)
                    let target = self.agentController.session!.snapshot().agents.first { $0.id == "agent_1" }!
                    let continuePath = env["PEBBLELAB_PS01_OCCUPANCY_LIVE_CAPTURE_DIR"]! + "/continue.png"
                    self.occupancyLiveCapturePath = continuePath
                    self.scheduleIncrement07LiveCapture(path: continuePath, phase: "occupancy-continue",
                        target: target.position, metadata: "Save/Continue complete worldTick=18052 living=24", terminateAfterCapture: false)
                    self.occupancyLiveStage = 3
                    return
                } else {
                    let expected = try JSONDecoder().decode(OccupancyQualificationBoundary.self,
                        from: Data(contentsOf: URL(fileURLWithPath: output)))
                    try PebbleContinuationEmbodimentQualification.verifyReader(self.game, self.agentController, expected: expected)
                    try PebbleContinuationEmbodimentQualification.require(self.game.saveAndFlush() && self.game.exitToTitle()
                        && self.agentController.probesByAgentId.isEmpty,
                        "rendered fresh reader Save/Continue and Save/Exit")
                }
                print("[lab-live] PS01_OCCUPANCY_NATIVE_PASS phase=\(phase) actualMetalCapture=\(path) saveContinue=PASS saveExit=PASS playerMutation=none externalEntityMutation=none"); fflush(stdout)
                NSApp.terminate(nil)
            } catch {
                fputs("[lab-live] PS01_OCCUPANCY_NATIVE_FAIL \(error)\n", stderr)
                exit(1)
            }
        }
    }

    private func scheduleIncrement07LiveCapture(
        path: String,
        phase: String,
        target: AgentPosition,
        metadata: String,
        terminateAfterCapture: Bool
    ) {
        guard increment07LiveRenderCapture == nil else {
            print(
                "[lab-live] PS01_INCREMENT_07_CAPTURE_FAIL reason=pending-capture "
                    + "phase=\(phase)"
            )
            fflush(stdout)
            return
        }
        increment07LiveRenderCapture = Increment07LiveRenderCapture(
            path: path,
            phase: phase,
            target: target,
            metadata: metadata,
            terminateAfterCapture: terminateAfterCapture,
            settleFramesRemaining: 1
        )
    }

    private func increment07LiveRenderCamera(overriding base: CamState) -> CamState {
        guard increment07LiveCaptureEnabled || increment08LivePhase != nil || occupancyLivePhase != nil,
              var request = increment07LiveRenderCapture else { return base }
        let player = game.player!
        let playerBefore = (player.x, player.y, player.z)
        var camera = base
        camera.x = Double(request.target.x) + 6.5
        camera.y = Double(request.target.y) + 4.0
        camera.z = Double(request.target.z) + 6.5
        let targetX = Double(request.target.x) + 0.5
        let targetY = Double(request.target.y) + 0.75
        let targetZ = Double(request.target.z) + 0.5
        let dx = targetX - camera.x
        let dy = targetY - camera.y
        let dz = targetZ - camera.z
        let horizontal = (dx * dx + dz * dz).squareRoot()
        camera.yaw = atan2(-dx, dz)
        camera.pitch = atan2(-dy, horizontal)
        let distance = (dx * dx + dy * dy + dz * dz).squareRoot()
        let forwardX = -sin(camera.yaw) * cos(camera.pitch)
        let forwardY = -sin(camera.pitch)
        let forwardZ = cos(camera.yaw) * cos(camera.pitch)
        let alignment = distance > 0
            ? (forwardX * dx + forwardY * dy + forwardZ * dz) / distance
            : -1
        let playerUnchanged = player.x == playerBefore.0
            && player.y == playerBefore.1
            && player.z == playerBefore.2
        guard camera.yaw.isFinite, camera.pitch.isFinite,
              alignment.isFinite, alignment >= 0.999_999,
              playerUnchanged else {
            print(
                "[lab-live] PS01_INCREMENT_07_CAPTURE_FAIL reason=invalid-render-camera "
                    + "phase=\(request.phase) alignment=\(alignment) "
                    + "playerUnchanged=\(playerUnchanged ? 1 : 0)"
            )
            fflush(stdout)
            increment07LiveRenderCapture = nil
            shotQuitFrames = 1
            return base
        }
        if request.settleFramesRemaining > 0 {
            request.settleFramesRemaining -= 1
            increment07LiveRenderCapture = request
        } else if pendingCompositedCapturePath == nil {
            pendingCompositedCapturePath = request.path
            increment07LiveRenderCapture = nil
            print(
                String(
                    format: "[lab-live] PS01_INCREMENT_07_CAPTURE phase=%@ %@ "
                        + "cameraAuthority=renderOnlyObserver camera=%.6f,%.6f,%.6f "
                        + "yawRadians=%.6f pitchRadians=%.6f alignment=%.9f "
                        + "player=%.6f,%.6f,%.6f playerUnchanged=1 "
                        + "harnessPlayerMutation=none settledRenderFrames=1 path=%@",
                    request.phase, request.metadata,
                    camera.x, camera.y, camera.z,
                    camera.yaw, camera.pitch, alignment,
                    player.x, player.y, player.z, request.path
                )
            )
            fflush(stdout)
            if request.terminateAfterCapture { shotQuitFrames = 180 }
        }
        return camera
    }

    private func captureWorkDemandRefreshMilestone(
        _ proof: PebblePassiveProductProofSnapshot
    ) {
        guard let directory = workDemandRefreshCaptureDirectory else { return }
        let milestones = [3, 8, 64]
        guard let milestone = milestones.first(where: {
            proof.simulationTick >= $0
                && !workDemandRefreshCapturedMilestones.contains($0)
        }) else { return }
        workDemandRefreshCapturedMilestones.insert(milestone)
        let name: String
        switch milestone {
        case 3: name = "corr04-before-first-refresh.png"
        case 8: name = "corr04-after-first-refresh.png"
        default: name = "corr04-later-active-society.png"
        }
        pendingCompositedCapturePath = directory + "/" + name
        print(
            "[lab-live] WORK_DEMAND_REFRESH_CAPTURE tick=\(proof.simulationTick) "
                + "milestone=\(milestone) path=\(name)"
        )
    }

    private func driveGateB3Passive(now: CFTimeInterval) {
        guard !gateB3PassiveCompleted, let duration = gateB3PassiveSeconds,
              let captureDirectory = gateB3PassiveCaptureDirectory,
              let proof = agentController.passiveProductProofSnapshot() else { return }
        gateB3PassiveMovementStayedEnabled =
            gateB3PassiveMovementStayedEnabled && proof.movementEnabled
                && proof.movementEverEnabled
        if gateB3PassiveStartedAt == nil {
            gateB3PassiveStartedAt = now
            gateB3PassiveInitialCompletions = proof.completions
            print(
                "[lab-live] GATE_B3_PASSIVE_WALL_START "
                    + "worldTick=\(game.world.time) simulationTick="
                    + "\(proof.simulationTick) "
                    + "durationTargetSeconds=\(Int(duration)) "
                    + "movementEnabled=\(proof.movementEnabled ? 1 : 0) "
                    + "aliveAgents=\(proof.aliveAgents) "
                    + "initialCompletions=\(proof.completions)"
            )
        }
        guard let startedAt = gateB3PassiveStartedAt else { return }
        let elapsed = now - startedAt
        let milestones = gateBConvergence
            ? [0, 30, 60, 90, Int(duration)]
            : [0, 60, 120, 180, 240, Int(duration)]
        for milestone in milestones where elapsed >= Double(milestone)
            && !gateB3PassiveCapturedMilestones.contains(milestone) {
            gateB3PassiveCapturedMilestones.insert(milestone)
            let name: String
            if gateBConvergence {
                switch milestone {
                case 0: name = "convergence-start.png"
                case 30: name = "convergence-role-neutral-emergence.png"
                case 60: name = "convergence-after-previous-home-boundary.png"
                case 90: name = "convergence-multi-agent.png"
                default: name = "convergence-late.png"
                }
            } else {
                switch milestone {
                case 0: name = "gate-b4-start.png"
                case 60: name = "gate-b4-multi-agent.png"
                case 120: name = "gate-b4-agriculture.png"
                case 180: name = "gate-b4-livestock.png"
                case 240: name = "gate-b4-follow-agent-late.png"
                default: name = "gate-b4-final.png"
                }
            }
            pendingCompositedCapturePath = captureDirectory + "/" + name
            print(
                String(
                    format: "[lab-live] GATE_B3_PASSIVE_CAPTURE "
                        + "milestoneSeconds=%d elapsedSeconds=%.3f path=%@",
                    milestone, elapsed, name
                )
            )
            break
        }
        guard elapsed >= duration else { return }
        gateB3PassiveCompleted = true
        agentController.traceGateB3AcceptanceSnapshot(world: game.world)
        if gateBConvergence {
            agentController.traceGateBConvergenceEvidence(world: game.world)
        }
        let initialCompletions = gateB3PassiveInitialCompletions ?? proof.completions
        print(
            String(
                format: "[lab-live] GATE_B3_PASSIVE_WALL_COMPLETE "
                    + "elapsedSeconds=%.3f targetSeconds=%.0f "
                    + "simulationTick=%d worldTick=%d productiveCommands=0 "
                    + "movementStayedEnabled=%d initialCompletions=%d "
                    + "finalCompletions=%d completionDelta=%d "
                    + "aliveAgents=%d runtimeErrors=%d",
                elapsed, duration,
                proof.simulationTick, game.world.time,
                gateB3PassiveMovementStayedEnabled ? 1 : 0,
                initialCompletions, proof.completions,
                proof.completions - initialCompletions,
                proof.aliveAgents, proof.runtimeErrors
            )
        )
        fflush(stdout)
        shotQuitFrames = 120
    }

    private func encodeCompositedCapture(_ cmd: MTLCommandBuffer, from texture: MTLTexture, to path: String) {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        guard !texture.isFramebufferOnly,
              let device = gameView.device,
              let buffer = device.makeBuffer(length: bytesPerRow * height, options: .storageModeShared),
              let blit = cmd.makeBlitCommandEncoder() else { return }
        blit.copy(
            from: texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: width, height: height, depth: 1),
            to: buffer,
            destinationOffset: 0,
            destinationBytesPerRow: bytesPerRow,
            destinationBytesPerImage: bytesPerRow * height
        )
        blit.endEncoding()
        cmd.addCompletedHandler { _ in
            let data = Data(bytes: buffer.contents(), count: bytesPerRow * height)
            guard let provider = CGDataProvider(data: data as CFData),
                  let image = CGImage(
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bitsPerPixel: 32,
                      bytesPerRow: bytesPerRow,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue
                          | CGImageAlphaInfo.noneSkipFirst.rawValue),
                      provider: provider,
                      decode: nil,
                      shouldInterpolate: false,
                      intent: .defaultIntent
                  ),
                  let destination = CGImageDestinationCreateWithURL(
                      URL(fileURLWithPath: path) as CFURL,
                      "public.png" as CFString,
                      1,
                      nil
                  ) else { return }
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
            print("[shot] captured \(path)")
            fflush(stdout)
        }
    }
}

if let occupancyStatus = PebbleContinuationEmbodimentQualification.runIfRequested() {
    exit(occupancyStatus)
}

if let blockerStatus = PebbleMortalityCheckpointBlockerHarness.runIfRequested() {
    exit(blockerStatus)
}

if let careStatus = PebbleCareNavigationBlockerHarness.runIfRequested() {
    exit(careStatus)
}

if let qualificationStatus = PebbleIncrement09QualificationHarness.runIfRequested() {
    exit(qualificationStatus)
}

if let continuationStatus = PebbleIncrement08ContinuationHarness.runIfRequested() {
    exit(continuationStatus)
}

if let faultStatus = PebbleIncrement07FaultHarness.runIfRequested() {
    exit(faultStatus)
}

if let restartStatus = PebbleIncrement07RestartHarness.runIfRequested() {
    exit(restartStatus)
}

if let invalidStartStatus = PebbleIncrement07InvalidStartHarness.runIfRequested() {
    exit(invalidStartStatus)
}

if let headlessStatus = PebbleIncrement05NaturalCharacterization
    .runIfRequested() {
    exit(headlessStatus)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)

// minimal main menu: Cmd-Q quits, Cmd-V pastes into UI fields (seeds!),
// Window gets the standard entries
let mainMenu = NSMenu()
let appItem = NSMenuItem()
let appMenu = NSMenu()
appMenu.addItem(withTitle: "About Pebble",
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
appMenu.addItem(NSMenuItem.separator())
appMenu.addItem(withTitle: "Quit Pebble",
                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appItem.submenu = appMenu
mainMenu.addItem(appItem)
let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Paste",
                 action: #selector(AppDelegate.pasteText(_:)), keyEquivalent: "v")
editItem.submenu = editMenu
mainMenu.addItem(editItem)
let winItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
let winMenu = NSMenu(title: "Window")
winMenu.addItem(withTitle: "Minimize",
                action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
winItem.submenu = winMenu
mainMenu.addItem(winItem)
app.mainMenu = mainMenu
app.windowsMenu = winMenu

app.run()
