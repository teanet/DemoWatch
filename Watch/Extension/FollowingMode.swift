import SpriteKit

enum FollowingMode {
	case disabled
	case center
	case following
}

extension FollowingMode {

	func texture() -> SKTexture {
		switch self {
			case .center: return SKTexture(imageNamed: "geo_enabled")
			case .disabled: return SKTexture(imageNamed: "geo_disabled")
			case .following: return SKTexture(imageNamed: "geo_following")
		}

	}

}
