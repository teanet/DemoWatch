import Foundation
import CoreLocation

public enum WatchSessionItem {
	case route(Route)
	case coordinate(CLLocationCoordinate2D)
	case none

	public var context: [String: Any] {
		switch self {
		case .route(let route):
			guard let data = try? JSONEncoder().encode(route) else { return [:] }
			return ["route" : data]
		case .coordinate(let coordinate):
			return ["coordinate" : [coordinate.latitude, coordinate.longitude]]
		case .none:
			return [:]
		}
	}

	public var isNone: Bool {
		if case .none = self {
			return true
		}
		return false
	}

}
