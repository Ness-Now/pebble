import Foundation
import PebbleCore

let world = World(dim: .overworld, seed: 12345)

for _ in 0..<20 {
    world.tick()
}

print("PebbleLab headless world ticked successfully: dim=\(world.dim.rawValue) seed=\(world.seed) ticks=\(world.time)")
