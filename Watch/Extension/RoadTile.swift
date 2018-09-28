import SpriteKit
import CoreLocation
import VNWatch

extension UIColor {

	static let noTraffic = #colorLiteral(red: 0.2862745098, green: 0.4196078431, blue: 0.7647058824, alpha: 1)

}

extension CarTrafficLoad {

	var color: UIColor {
		switch self {
		case .fast: 		return #colorLiteral(red: 0.2705882353, green: 0.7176470588, blue: 0, alpha: 1)
		case .ignore: 		return #colorLiteral(red: 0.5058823529, green: 0.007843137255, blue: 0.05098039216, alpha: 1)
		case .noTraffic: 	return .noTraffic
		case .normal: 		return #colorLiteral(red: 1, green: 0.7529411765, blue: 0, alpha: 1)
		case .slow: 		return #colorLiteral(red: 0.9497485757, green: 0.3531837463, blue: 0, alpha: 1)
		case .inactive:		return #colorLiteral(red: 0.5019607843, green: 0.5019607843, blue: 0.5019607843, alpha: 1)
		}
	}

}

extension Route {

	func node(
		z: Int,
		center: CGPoint,
		lineWidth: CGFloat,
		strokeColor: UIColor
	) -> SKShapeNode {
		let path = UIBezierPath()
		let points = self.pathComponents.flatMap { $0.path }
		for p in points {
			let point = p.location(for: z) - center
			if path.isEmpty {
				path.move(to: point)
			} else {
				path.addLine(to: point)
			}
		}
		let node = SKShapeNode(path: path.cgPath)
		node.strokeColor = strokeColor
		node.lineWidth = lineWidth
		node.lineJoin = .miter
		node.lineCap = .round
		node.isAntialiased = true
		node.fillColor = .clear
		return node
	}

}

extension RoadTile {

	convenience init(z: Int) {
		self.init()
		self.z = z
	}

}

final class RoadTile: SKShapeNode {

	private var z: Int = 1
	var center: CGPoint = .zero

	var route: Route? {
		didSet {
			self.removeAllChildren()
			guard let route = self.route else { return }
			if let startPoint = route.startPoint {
				self.center = startPoint.location(for: self.z)
			}
			DispatchQueue.global(qos: .userInitiated).async {
				let blueNode = route.node(z: self.z, center: self.center, lineWidth: 6, strokeColor: .noTraffic)
				let whiteNode = route.node(z: self.z, center: self.center, lineWidth: 8, strokeColor: .white)
				DispatchQueue.main.async {
					self.addChild(whiteNode)
					self.addChild(blueNode)
				}
			}
		}
	}

}

