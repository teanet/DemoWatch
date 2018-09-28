import SpriteKit
import VNWatch

final class RouteNodes {
	private let routeA = SKNode.image(#imageLiteral(resourceName: "route_a"))
	private let routeB = SKNode.image(#imageLiteral(resourceName: "route_b"))
	private let selectedRoute = SKNode.image(#imageLiteral(resourceName: "route_movement"))

	var nodes: [SKSpriteNode] {
		return [ self.routeA, self.selectedRoute, self.routeB ]
	}

	func update(z: Int, correction: CGPoint, route: Route, selectedManeuver: Maneuver?) {
		if let startPoint = route.startPoint, let endPoint = route.endPoint {
			self.routeA.isHidden = false
			self.routeB.isHidden = false

			self.routeA.position = startPoint.location(for: z) + correction
			self.routeB.position = endPoint.location(for: z) + correction

			if let maneuverCoordinate = selectedManeuver?.startPoint {
				self.selectedRoute.isHidden = false
				self.selectedRoute.position = maneuverCoordinate.location(for: z) + correction
			}
		} else {
			self.hide()
		}
	}

	func hide() {
		self.nodes.forEach { $0.isHidden = true }
	}

}
