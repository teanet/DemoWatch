import Foundation
import MapKit

let kTileLength: CGFloat = 256
let kTileSize = CGSize(width: kTileLength, height: kTileLength)

struct TilePath: Hashable {

	static func ==(lhs: TilePath, rhs: TilePath) -> Bool {
		return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
	}

	public static func - (left: TilePath, right: TilePath) -> TilePath {
		assert(left.z == right.z)
		return TilePath(x: left.x - right.x, y: left.y - right.y, z: left.z)
	}
	public static func + (left: TilePath, right: TilePath) -> TilePath {
		assert(left.z == right.z)
		return TilePath(x: left.x + right.x, y: left.y + right.y, z: left.z)
	}

	let x: Int
	let y: Int
	let z: Int

	func tilesAround() -> [TilePath] {
		var tiles = [TilePath]()
		for x in (x - 1)...(x + 1) {
			for y in (y - 1)...(y + 1) {
				if x == self.x && y == self.y {
				} else {
					tiles.append(TilePath(x: x, y: y, z: self.z))
				}
			}
		}
		return tiles
	}

	var isValid: Bool {
		let zoom = 2 ^^ self.z
		return self.x >= 0 && self.y >= 0 && self.x < zoom && self.y < zoom
	}

	func url() -> URL {
		let url = "https://tile2.maps.2gis.com/tiles?x=\(self.x)&y=\(self.y)&z=\(self.z)&v=1.3&ts=online_hd"
		return URL(string: url)!
	}
	func imageName() -> String {
		return "\(self.x)-\(self.y)-\(self.z)"
	}

	var position: CGPoint {
		let x = CGFloat(self.x)
		let y = CGFloat(self.y)
		let offset: CGFloat = pow(2, CGFloat(self.z - 1))
		return CGPoint(x: kTileLength * ( -offset + x ),
					   y: kTileLength * ( offset - y - 1 ))
	}

	var center: CGPoint {
		return self.position + CGPoint(x: kTileLength, y: kTileLength) * 0.5
	}

	var tileFrame: CGRect {
		return CGRect(center: self.center, size: kTileSize)
	}

}

