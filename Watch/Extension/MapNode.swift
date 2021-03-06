import SpriteKit
import WatchKit
import VNWatch

protocol MapNodeDelegate: AnyObject {

	func updateFollowingMode()
	func cameraPositionDidChange(_ position: CGPoint, animated: Bool, completion: @escaping () -> Void)
	func cameraScaleDidChange(_ scale: CGFloat)

}

final class MapNode: SKSpriteNode {

	var lastUserCoordinate: CLLocationCoordinate2D?
	var sceneFrame: CGRect = .zero
	var cameraPosition: CGPoint = .zero

	var sessionItem: WatchSessionItem = .empty {
		didSet {
			self.updateSessionItemNodes()
		}
	}
	var selectedManeuver: Maneuver? {
		didSet {
			if let point = self.selectedManeuver?.startPoint {
				self.move(to: point, zoomLevel: .kBuildingZoomLevel)
				self.updateRoute()
			}
		}
	}

	var zoomLevel: Int = 1
	weak var delegate: MapNodeDelegate?

	let userLocationNode = UserLocationNode()
	private let destinationNode = SKNode.image(#imageLiteral(resourceName: "pin"))
	private var cameraScaleNodes = [SKNode]()

	private let tileLoader: TileLoader
	private var zoomNodes = [Int: MapLayerNode]()
	private let routeNodes = RouteNodes()

	/// Нужно постоянно корректировать положение тайлов,
	/// чтобы они были максимально близко к 0,0 иначе спрайтовый движок начинает очень сильно колбасить при зуме
	/// и между тайлами образуются щели
	var scale: CGFloat = 1 {
		didSet {
			let to = Int(round(self.scale))
			if self.zoomLevel != to {
				let current = self.zoomLevel

				let currentWorldAnchor = self.worldPosition(z: current).anchor(for: current)
				let visibleTile = currentWorldAnchor.pointFormAnchor(for: to).visibleTile(for: to)
				self.zoomNodes.forEach { (kv) in
					kv.value.isHidden = kv.key != to
					if kv.key == to {
						kv.value.visibleTile = visibleTile
					} else {
						kv.value.clean()
					}
				}
				let toNode = self.zoomNodes[to]!
				self.cameraPosition = currentWorldAnchor.pointFormAnchor(for: to) + toNode.correction
				self.delegate?.cameraPositionDidChange(self.cameraPosition, animated: false, completion: {})
				self.zoomLevel = to

				self.loadVisibleTiles()
			}
			self.updateRoute()
			self.updateCurrentLocationNode()
			self.updateDestinationNode()
			self.updateToCurrentScale()
		}
	}
	var currentNode: MapLayerNode {
		return self.zoomNodes[self.zoomLevel]!
	}
	var currentLocation: CLLocationCoordinate2D? {
		didSet {
			self.userLocationNode.isHidden = self.currentLocation == nil
		}
	}

	init(tileLoader: TileLoader) {
		self.tileLoader = tileLoader

		super.init(texture: nil, color: .white, size: .zero)
		self.destinationNode.anchorPoint = CGPoint(x: 0.5, y: 0)

		self.zoomNodes = {
			var zoomNodes = [Int: MapLayerNode]()
			for z in 1...18 {
				let node = MapLayerNode(z: z, tileLoader: self.tileLoader)
				zoomNodes[z] = node
				self.insertChild(node, at: 0)
			}
			return zoomNodes
		}()

		// userLocationNode всегда должна быть последней
		self.cameraScaleNodes = self.routeNodes.nodes + [ self.destinationNode, self.userLocationNode ]
		self.cameraScaleNodes.forEach {
			$0.isHidden = true
			self.addChild($0)
		}
	}
	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func loadVisibleTiles() {
		let z = self.zoomLevel
		let cameraFrame = self.cameraFrame()
		self.zoomNodes[z]!.loadVisibleTiles(forCameraFrame: cameraFrame)
	}

	func updateCurrentLocationNode() {
		guard let currentLocation = self.currentLocation else { return }

		let dc = currentLocation.location(for: self.zoomLevel)
		self.userLocationNode.position = dc + self.currentNode.correction

		if let lastUserCoordinate = self.lastUserCoordinate, !lastUserCoordinate.isNear(currentLocation) {
			self.delegate?.updateFollowingMode()
		}
	}

	func move(to: CLLocationCoordinate2D, zoomLevel: CGFloat, completion: (() -> Void)? = nil) {
		self.lastUserCoordinate = to
		let positionInWorld = to.location(for: self.zoomLevel)
		let visibleTile = positionInWorld.visibleTile(for: self.zoomLevel)

		let shouldAnimate = self.currentNode.visibleTile == visibleTile
		self.currentNode.visibleTile = visibleTile
		self.cameraPosition = positionInWorld + self.currentNode.correction
		self.updateCurrentLocationNode()

		self.delegate?.updateFollowingMode()
		self.delegate?.cameraPositionDidChange(self.cameraPosition, animated: shouldAnimate, completion: { [weak self] in
			self?.scale = zoomLevel
			self?.loadVisibleTiles()
		})
	}

	private func worldPosition(z: Int) -> CGPoint {
		let currentPosition = self.cameraPosition - self.zoomNodes[self.zoomLevel]!.correction
		let anchor = currentPosition.anchor(for: self.zoomLevel)
		let toPosition = anchor.pointFormAnchor(for: z)
		return toPosition
	}

	private func cameraScale() -> CGFloat {
		let scale = 1 + pow(2, self.scale - 1)
		let cameraScale = scale / pow(2, CGFloat(self.zoomLevel - 1))
		let nodeScale = 1 / cameraScale
		return nodeScale
	}

	private func cameraFrame() -> CGRect {
		let nodeScale = self.cameraScale()
		let visibleFrame = self.sceneFrame.applying(.init(scaleX: nodeScale, y: nodeScale))
		return CGRect(center: self.cameraPosition, size: visibleFrame.size)
	}

	private func updateToCurrentScale() {
		let nodeScale = self.cameraScale()

		self.delegate?.cameraScaleDidChange(nodeScale)
		self.cameraScaleNodes.forEach { $0.setScale(nodeScale) }
	}

	func moveToCenter(zoomLocation: CGFloat) {
		if let location = self.currentLocation {
			self.move(to: location, zoomLevel: zoomLocation)
		}
	}

	func updateSessionItemNodes() {

		self.routeNodes.hide()
		self.destinationNode.isHidden = true
		self.zoomNodes.forEach { $0.value.route = nil }

		switch self.sessionItem {
			case .coordinate:
				self.destinationNode.isHidden = false
				self.updateDestinationNode()
			case .route(let route):
				self.zoomNodes.forEach { $0.value.route = route }
				self.updateRoute()
			case .empty:
				break
		}

	}

	private func updateRoute() {
		guard case .route(let route) = self.sessionItem else { return }

		self.routeNodes.update(
			z: self.zoomLevel,
			correction: self.currentNode.correction,
			route: route,
			selectedManeuver: self.selectedManeuver
		)
	}

	private func updateDestinationNode() {
		guard case .coordinate(let coordinate) = self.sessionItem else { return }

		let dc = coordinate.location(for: self.zoomLevel)
		self.destinationNode.position = dc + self.currentNode.correction
	}

}
