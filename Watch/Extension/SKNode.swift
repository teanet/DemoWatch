import SpriteKit

extension SKNode {

	static func named(_ name: String) -> SKSpriteNode {
		return SKSpriteNode(texture: SKTexture(image: UIImage(named: name)!))
	}
	static func image(_ image: UIImage) -> SKSpriteNode {
		return SKSpriteNode(texture: SKTexture(image: image))
	}

	func blink() {
		self.run(.colorize(with: UIColor.black, colorBlendFactor: 0.5, duration: 0.1)) {
			self.run(.colorize(with: UIColor.clear, colorBlendFactor: 0.0, duration: 0.1))
		}
	}

}
