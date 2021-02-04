import SpriteKit
import CoreLocation

final class UserLocationNode: SKNode {

	let direction = SKNode.named("direction")

	var heading: CLHeading? {
		didSet {
			
			self.updateDirection()
		}
	}

	override init() {
		super.init()

		self.addChild(self.direction)

		let location = SKNode.image(#imageLiteral(resourceName: "geo"))
		self.addChild(location)
		self.updateDirection()
	}

	private func updateDirection() {
		self.direction.isHidden = self.heading == nil
		guard let heading = self.heading else { return }

		let radianHeading = heading.trueHeading / 180 * .pi
		let scale = 0.5 * max(0, min(1, heading.headingAccuracy / 40))
		print(">>>>> \(scale) \(heading.trueHeading) \(heading.headingAccuracy) \(radianHeading)")
		let group = SKAction.group([
			.scaleX(to: CGFloat(scale), y: 0.5, duration: 0.1),
			.rotate(toAngle: CGFloat(-radianHeading), duration: 0, shortestUnitArc: true)
		])
		self.direction.run(group, withKey: "heading")
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
