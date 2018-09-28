import Foundation
import CoreLocation
import WatchKit

public struct Geometry: Codable {
	let color: CarTrafficLoad?
	let selection: String
}

public struct PedestrianPath: Codable {
	let geometry: Geometry
}

public struct OutcomingPath: Codable {
	public let distance: Float
	public let duration: Float
	public let geometries: [Geometry]

	enum CodingKeys: String, CodingKey {
		case distance = "distance"
		case duration = "duration"
		case geometries = "geometry"
	}
}

public struct Maneuver: Codable {

	public let id: String
	public let type: String
	public let comment: String
	public let outcomingPathComment: String
	public let outcomingPath: OutcomingPath?
	public let turnDirection: String?
	public let iconName: String?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case type = "type"
		case comment = "comment"
		case outcomingPathComment = "outcoming_path_comment"
		case outcomingPath = "outcoming_path"
		case turnDirection = "turn_direction"
		case iconName = "icon"
	}
}

public struct Route: Codable {

	public let maneuvers: [Maneuver]
	public let beginPedestrianPath: PedestrianPath?
	public let endPedestrianPath: PedestrianPath?

	enum CodingKeys: String, CodingKey {
		case maneuvers = "maneuvers"
		case beginPedestrianPath = "begin_pedestrian_path"
		case endPedestrianPath = "end_pedestrian_path"
	}
}

extension Maneuver {

	public var startPoint: CLLocationCoordinate2D? {
		return self.outcomingPath?.geometries.first?.path.first
	}
	public var endPoint: CLLocationCoordinate2D? {
		return self.outcomingPath?.geometries.last?.path.last
	}

	public var image: UIImage? {
		guard let icon = self.iconName else { return nil }
		if let image = UIImage(named: "\(icon)") {
			return image
		}
		switch icon {
			case "turn_over_right_hand": return UIImage(named: "crossroad_uturn")
			case "turn_over_left_hand": return UIImage(named: "L_crossroad_uturn")
			default: return nil
		}
	}

}


public extension Route {

	public var pathComponents: [PathComponent] {
		return self.maneuvers.flatMap { (maneuver) -> [Geometry] in
			maneuver.outcomingPath?.geometries ?? []
		}.map {
			PathComponent(color: $0.color ?? .fast, path: $0.path)
		}
	}

	public var startPoint: CLLocationCoordinate2D? {
		if let startPoint = self.beginPedestrianPath?.geometry.path.first {
			return startPoint
		}
		return self.maneuvers.first(where: { $0.outcomingPath?.geometries.isEmpty == false })?.startPoint
	}
	public var endPoint: CLLocationCoordinate2D? {
		if let endPoint = self.endPedestrianPath?.geometry.path.last {
			return endPoint
		}
		return self.maneuvers.reversed().first(where: { $0.outcomingPath?.geometries.isEmpty == false })?.endPoint
	}

}

public enum CarTrafficLoad: String, Codable {
	case slow
	case normal
	case fast
	case ignore
	case noTraffic = "no-traffic"
	case inactive
}

public struct PathComponent {
	public let color: CarTrafficLoad
	public let path: [CLLocationCoordinate2D]
}

public extension Geometry {

	public var path: [CLLocationCoordinate2D] {
		guard self.selection.hasPrefix("LINESTRING(") else { return [] }
		var selection = self.selection
		selection = selection.replacingOccurrences(of: "LINESTRING(", with: "")
		selection = selection.replacingOccurrences(of: ")", with: "")
		let lonLats = selection.components(separatedBy: ", ")
		return lonLats.compactMap({ lonLat -> CLLocationCoordinate2D? in
			let cmps = lonLat.components(separatedBy: " ")
			guard cmps.count == 2,
				let lon = CLLocationDegrees(cmps[0]),
				let lat = CLLocationDegrees(cmps[1]) else { return nil }

			return CLLocationCoordinate2D(latitude: lat, longitude: lon)
		})
	}

}
