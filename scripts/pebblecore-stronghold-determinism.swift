// Compile against the selected PebbleCore build; one fresh process per seed.
import Foundation
import CryptoKit
import PebbleCore
registerAllBlocks(); registerAllItems(); registerAllBiomes(); registerAllRecipes(); registerAllLootTables(); registerAllEntities(); registerAllSystems(); registerAllStructures()
let seed = UInt32(CommandLine.arguments[1])!
let positions = strongholdPositions(seed)
let ctx = GenCtx(seed: seed, heightAt: {_,_ in 64}, biomeAt: {_,_ in 0}, dim: 0)
let def = STRUCTURES.first { $0.id == "stronghold" }!
let plans = positions.map { x,z -> [String: Any] in
    let plan = getPlan(def, ctx, x, z)!
    return ["origin": [x,z], "pieces": plan.pieces.map { [$0.x0,$0.y0,$0.z0,$0.x1,$0.y1,$0.z1] }, "ref": plan.ref.map { [$0.x0,$0.y0,$0.z0,$0.x1,$0.y1,$0.z1] } ?? []]
}
func digest<T>(_ a: [T]) -> String { a.withUnsafeBytes { SHA256.hash(data: Data($0)).map { String(format: "%02x", $0) }.joined() } }
var chunks: [[String: Any]] = []
for (dim,x,z) in [(Dim.overworld,positions[0].0,positions[0].1),(Dim.overworld,positions[0].0+1,positions[0].1),(Dim.overworld,0,0),(Dim.nether,0,0),(Dim.end,0,0)] {
 let out = generateChunk(dim,seed,x,z)
 chunks.append(["dim":dim.rawValue,"cx":x,"cz":z,"blocks":digest(out.blocks),"biomes":digest(out.biomes),"bes":out.blockEntities.map { be in [be.x,be.y,be.z,be.kind,be.data.keys.sorted().map { [$0,String(describing:be.data[$0]!)] }] as [Any] },"entities":out.entities.map { e in [e.mob,e.x,e.y,e.z,e.data.keys.sorted().map { [$0,String(describing:e.data[$0]!)] }] as [Any] },"refs":out.structRefs.map { [$0.id,$0.x0,$0.y0,$0.z0,$0.x1,$0.y1,$0.z1] as [Any] }])
}
let data = try! JSONSerialization.data(withJSONObject: ["seed":seed,"positions":positions.map { [$0.0,$0.1] },"plans":plans,"chunks":chunks],options:[.sortedKeys])
print(String(data:data,encoding:.utf8)!)
