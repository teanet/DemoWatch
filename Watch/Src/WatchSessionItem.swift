import Foundation
import CoreLocation

public enum WatchSessionItem {
	case route(Route)
	case coordinate(CLLocationCoordinate2D)
	case empty

	public var context: [String: Any] {
		switch self {
			case .route(let route):
				guard let data = try? JSONEncoder().encode(route) else { return [:] }
				return ["route" : data]
			case .coordinate(let coordinate):
				return ["coordinate" : [coordinate.latitude, coordinate.longitude]]
			case .empty:
				return [:]
		}
	}

	public var desription: String {
		switch self {
			case .coordinate(_): return "WCSession did receive location"
			case .empty: return "WCSession did clear"
			case .route(_): return "WCSession did receive route"
		}
	}

	public var name: String? {
		switch self {
			case .coordinate(_): return "WatchAppShowObject"
			case .empty: return nil
			case .route(_): return "WatchAppShowRoute"
		}
	}

	public var isEmpty: Bool {
		if case .empty = self {
			return true
		}
		return false
	}

}

