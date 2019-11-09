import SpriteKit

final class TileNode: SKSpriteNode {

	static let bgTexture = SKTexture(image: UIImage(imageLiteralResourceName: "tile_bg"))
	private var tileLoader: TileLoader!
	private var isLoading = false
	private var mapTileNode: SKSpriteNode?
	private var currentPath: TilePath?

	deinit {
		if let path = self.currentPath {
			self.tileLoader.cancel(for: path)
		}
	}

	convenience init(tileLoader: TileLoader) {
		self.init(texture: TileNode.bgTexture)
		self.tileLoader = tileLoader
		self.size = kTileSize
	}

	func load(_ path: TilePath, priority: Float) {
		guard !self.isLoading && self.mapTileNode == nil else { return }

		if let texture = self.tileLoader[path] {
			print("TileNode>>>>>\(path) take texture from cache, url: \(path.url())")
			self.updateTileTexture(texture, path: path, animated: false)
			return
		}

		self.isLoading = true
		self.tileLoader.loadTile(at: path, priority: priority) { [weak self] (result, path) in
			switch result {
				case .texture(let texture):
					self?.updateTileTexture(texture, path: path, animated: true)
				case .cancelled: break
				case .error: break
			}
			self?.isLoading = false
		}
	}

	func updateTileTexture(_ texture: SKTexture, path: TilePath, animated: Bool) {
		let node = SKSpriteNode(texture: texture)
		node.size = kTileSize
		self.insertChild(node, at: 0)
		if animated {
			node.alpha = 0
			node.run(.fadeIn(withDuration: 0.3))
		}
		self.mapTileNode = node
	}

}
