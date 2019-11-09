import SpriteKit
import VNWatch

final class MapLayerNode: SKNode {

	let z: Int
	var tiles = [TilePath: TileNode]()
	var correction = CGPoint.zero
	var route: Route? {
		didSet {
			self.routeDidDisplay = false
			self.updateRouteIfNeeded()
			self.routeDidDisplay = !self.isHidden
		}
	}
	private let zeroTile: TilePath
	private let roadTile: RoadTile
	private var routeDidDisplay: Bool = false

	var visibleTile: TilePath {
		didSet {
			let offset = self.zeroTile - self.visibleTile
			self.correction = CGPoint(x: CGFloat(offset.x) * kTileLength, y: -CGFloat(offset.y) * kTileLength)
			self.tiles.forEach { (kv) in
				kv.value.position = kv.key.center + self.correction
			}
			self.updateRouteTilePosition()
		}
	}
	private let tileLoader: TileLoader
	override var isHidden: Bool {
		didSet {
			self.updateRouteIfNeeded()
		}
	}

	init(z: Int, tileLoader: TileLoader) {
		self.z = z
		self.tileLoader = tileLoader
		let offset = 2 ^^ (z - 1)
		self.zeroTile = TilePath(x: offset, y: offset - 1, z: z)
		self.visibleTile = TilePath(x: 0, y: 0, z: z)
		self.roadTile = RoadTile(z: z)
		super.init()
		self.addChild(self.roadTile)
	}

	func loadVisibleTiles(forCameraFrame frame: CGRect) {
		let realFrame = CGRect(center: frame.center - self.correction, size: frame.size)
		let centerTile = realFrame.center.visibleTile(for: self.z)
		var toLoadTiles = [TilePath]()
		toLoadTiles.append(centerTile)
		self.loadTile(path: centerTile, priority: 1)

		centerTile.tilesAround().forEach {
			let priority: Float = $0.isValid && $0.tileFrame.intersects(realFrame) ? 0.5 : 0
			self.loadTile(path: $0, priority: priority)
			if priority > 0 {
				toLoadTiles.append($0)
			}
		}
		print("loadVisibleTiles: \(toLoadTiles)")
	}

	func clean() {
		for tile in self.tiles {
			tile.value.removeFromParent()
		}
		self.tiles.removeAll()
	}

	private func updateRouteIfNeeded() {
		if !self.isHidden && !self.routeDidDisplay {
			self.roadTile.route = self.route
			self.updateRouteTilePosition()
			self.routeDidDisplay = true
		}
	}

	private func updateRouteTilePosition() {
		self.roadTile.position = self.roadTile.center + self.correction
	}

	func loadTile(path: TilePath, priority: Float) {
		if let node = self.putTileIfNeeded(path: path), priority > 0 {
			node.load(path, priority: priority)
		}
	}

	func putTileIfNeeded(path: TilePath) -> TileNode? {
		if let node = self.tiles[path] {
			return node
		}
		guard path.z == self.z else {
			print(">>>>>Something goes wrong, load \(path) for zoom level \(self.z)")
			return nil
		}

		let node = TileNode(tileLoader: self.tileLoader)
		node.position = path.center + self.correction
		self.insertChild(node, at: 0)
		self.tiles[path] = node
		return node
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
