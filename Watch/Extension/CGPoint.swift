import UIKit

extension CGPoint {
	public static func + (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x + right.x, y: left.y + right.y)
	}
	public static func - (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x - right.x, y: left.y - right.y)
	}
	public static func / (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x / right, y: left.y / right)
	}
	public static func * (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x * right, y: left.y * right)
	}

	func visibleTile(for z: Int) -> TilePath {
		let x = Int( round( 0.5 + self.x / kTileLength ) )
		let y = -Int( round( -0.5 + self.y / kTileLength ) )
		let offset = 2 ^^ (z - 1) - 1
		let tile = TilePath(x: x + offset, y: y + offset, z: z)
		return tile
	}

	func tileBelow(forZ z: Int) -> TilePath {
		let x = Int( round( 0.5 + self.x / kTileLength ) )
		let y = -Int( round( -0.5 + self.y / kTileLength ) )
		return TilePath(x: x, y: y, z: z)
	}

	func anchor(for scale: Int) -> CGPoint {
		let s = CGFloat(scale)
		let p = kTileLength * 0.5 * pow(2, s)
		return self / p
	}

	static func upperLeft(for z: Int) -> CGPoint {
		let halfWorldSize = kTileLength * pow(2, CGFloat(z - 1))
		return CGPoint(x: -halfWorldSize, y: halfWorldSize)
	}

	func pointFormAnchor(for scale: Int) -> CGPoint {
		let s = CGFloat(scale)
		let p = kTileLength * pow(2, s - 1)
		return self * p
	}

}

extension CGRect {

	init(center: CGPoint, size: CGSize) {
		self.init(origin: CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5), size: size)
	}
	var center: CGPoint {
		return CGPoint(x: self.midX, y: self.midY)
	}

}
