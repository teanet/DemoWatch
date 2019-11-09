import CoreLocation
import UIKit

extension CLLocationCoordinate2D {

	func isNear(_ to: CLLocationCoordinate2D) -> Bool {
		let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
		let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
		return to.distance(from: from) < 50
	}

	static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}

	func tileLocation() -> CGPoint {
		var siny = sin(self.latitude * .pi / 180)
		siny = min(max(siny, -1), 1)
		let y = CGFloat(log( ( 1 + siny ) / ( 1 - siny )))
		return CGPoint(
			x: kTileLength * ( 0.5 + CGFloat(self.longitude) / 360 ),
			y: kTileLength * ( 0.5 - y / ( 4 * .pi ) )
		)
	}

	func tilePath(for scale: Int) -> TilePath {
		let tile = self.tileLocation()
		let zoom: CGFloat = pow(2, CGFloat(scale))
		return TilePath(
			x: Int(floor(tile.x * zoom) / kTileLength),
			y: Int(floor(tile.y * zoom) / kTileLength),
			z: scale
		)
	}

	func location(for scale: Int) -> CGPoint {
		let tile = self.tileLocation()
		let zoom: CGFloat = pow(2, CGFloat(scale))
		let offset = kTileLength * 0.5
		return CGPoint(
			x: (tile.x - offset ) * zoom,
			y: (-tile.y + offset) * zoom
		)
	}

}
