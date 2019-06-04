import WatchKit
import Foundation
import SpriteKit
import MapKit
import WatchConnectivity
import VNWatch

final class InterfaceController: WKInterfaceController, CLLocationManagerDelegate, WCSessionDelegate, WKCrownDelegate, MapNodeDelegate, RouteControllerDelegate {

	@IBOutlet var sk: WKInterfaceSKScene!

	private let rootNode: MapNode
	private let scene = SKScene()
	private let moveToUserLocationNode = SKNode.named("geo_disabled")
	private let camera = SKCameraNode()
	private var isTracking: Bool = false {
		didSet {
			if self.isTracking != oldValue {
				self.updateMoveToUserLocationNode()
			}
		}
	}
	private var isPanGestureInProgress = false {
		didSet {
			if self.isPanGestureInProgress != oldValue {
				self.updateMoveToUserLocationNode()
				self.rootNode.updateCurrentLocationNode()
			}
		}
	}

	/// Текущая позиция камеры
	private var cameraPosition = CGPoint.zero {
		didSet {
			self.rootNode.cameraPosition = self.cameraPosition
		}
	}
	private weak var interactionTimer: Timer?

	private let tileLoader = TileLoader()
	private lazy var locationManager = CLLocationManager()
	private var scheduledSessionItem: WatchSessionItem? {
		didSet {
			if let description = self.scheduledSessionItem?.desription {
				print(description)
			}
			if let name = self.scheduledSessionItem?.name {
				Analytics.track(name)
			}
		}
	}

	override init() {
		self.rootNode = MapNode(tileLoader: self.tileLoader)
		super.init()
		self.setTitle("2GIS")
	}

	private var isInterfaceReady = false
	override func didAppear() {
		super.didAppear()

		self.rootNode.sceneFrame = self.scene.frame
		if !self.isInterfaceReady {
			self.rootNode.currentLocation = self.locationManager.location?.coordinate
			self.rootNode.scale = 2

			self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
			self.locationManager.delegate = self
			self.isInterfaceReady = true
		}
		self.updateMoveToUserLocationNode()
	}

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		WCSession.default.delegate = self
		WCSession.default.activate()

		self.rootNode.delegate = self
		self.sk.preferredFramesPerSecond = 60
		self.scene.scaleMode = .resizeFill
		self.sk.presentScene(self.scene)

		self.scene.addChild(self.rootNode)

		self.scene.addChild(self.camera)
		self.scene.camera = self.camera

		self.camera.addChild(self.moveToUserLocationNode)
	}

	override func willActivate() {
		super.willActivate()
		self.crownSequencer.delegate = self
		self.crownSequencer.focus()
		Analytics.track("WatchAppActivated", value: nil)
	}

	@IBAction func tap(_ sender: WKTapGestureRecognizer) {
		let size = CGSize(width: 50, height: 50)
		let origin = CGPoint(x: self.scene.frame.width - size.width, y: self.scene.frame.height - size.height)
		let frame = CGRect(origin: origin, size: size)
		if frame.contains(sender.locationInObject()) {
			self.moveToUserLocationNode.blink()
			self.isTracking = true
			self.rootNode.moveToCenter(zoomLocation: .kBuildingZoomLevel)
		} else if case .route(let route) = self.rootNode.sessionItem {
			let ctx = RouteControllerContext.init(route: route, selectedManeuver: self.rootNode.selectedManeuver, delegate: self)
			Analytics.track("WatchAppShowRouteController")
			self.pushController(withName: "RouteController", context: ctx)
		}
	}

	@IBAction func pan(_ sender: WKPanGestureRecognizer) {
		switch sender.state {
		case .changed:
			self.isPanGestureInProgress = true
			let tr = sender.translationInObject()
			self.camera.position = CGPoint(
				x: self.cameraPosition.x - tr.x,
				y: self.cameraPosition.y + tr.y
			)
		case .ended, .failed, .cancelled:
			self.cameraPosition = self.camera.position
			self.rootNode.loadVisibleTiles()
			self.isPanGestureInProgress = false
			/// Stop tracking user location if user pan map
			self.isTracking = false
		default:
			break
		}
	}

	private func updateMenuItems(_ item: WatchSessionItem) {
		self.clearAllMenuItems()
		if !item.isEmpty {
			self.addMenuItem(with: .trash, title: "", action: #selector(self.clearLastOpenObject))
		}
	}

	@objc private func clearLastOpenObject() {
		self.scheduledSessionItem = .empty
		self.startInteractionTimer()
	}

	private func updateSessionItem(_ item: WatchSessionItem) {
		// Есть баг в SpriteKit что если пытаться быстро отрисовывать маршрут то может упасть по EXC_BAD_ACCESS
		DispatchQueue.main.async { [weak self] in
			self?.rootNode.sessionItem = item
			self?.updateMenuItems(item)
		}
	}

	// MARK: CLLocationManagerDelegate

	private var updateUserLocationAtLeastOnce = false
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		self.rootNode.currentLocation = manager.location?.coordinate
		guard let location = manager.location, !self.isPanGestureInProgress else { return }

		if !self.updateUserLocationAtLeastOnce {
			self.updateUserLocationAtLeastOnce = true
			self.rootNode.move(to: location.coordinate, zoomLevel: .kDistrictZoomLevel)
			self.updateMoveToUserLocationNode()
		} else if self.isTracking {
			self.rootNode.move(to: location.coordinate, zoomLevel: self.rootNode.scale)
		} else {
			self.rootNode.updateCurrentLocationNode()
		}
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
			case .notDetermined:
				manager.requestWhenInUseAuthorization()
			case .authorizedAlways, .authorizedWhenInUse:
				manager.startUpdatingLocation()
			default: break
		}
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

	// MARK: WCSessionDelegate

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("ActivationDidCompleteWithState: \(activationState.rawValue)", error ?? "")
	}

	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		if applicationContext.isEmpty {
			self.scheduledSessionItem = .empty
		} else if let c = applicationContext as? [String: [CLLocationDegrees]],
			let latLon = c["coordinate"] {
			let coordinate = CLLocationCoordinate2D(latitude: latLon[0], longitude: latLon[1])
			self.scheduledSessionItem = .coordinate(coordinate)
		} else if let c = applicationContext as? [String: Data],
			let routeData = c["route"],
			let route = try? JSONDecoder().decode(Route.self, from: routeData) {
			self.scheduledSessionItem = .route(route)
		} else {
			self.scheduledSessionItem = .empty
		}
		DispatchQueue.main.async {
			self.startInteractionTimer()
		}
	}

	private func startInteractionTimer() {
		self.interactionTimer?.invalidate()
		self.interactionTimer = Timer.scheduledTimer(
			timeInterval: 0.3,
			target: self,
			selector: #selector(self.interactionDidEnd),
			userInfo: nil,
			repeats: false
		)
	}

	@objc private func interactionDidEnd() {
		self.rootNode.loadVisibleTiles()
		if let item = self.scheduledSessionItem {
			self.updateSessionItem(item)
			self.scheduledSessionItem = nil
		}
	}

	// MARK: WKCrownDelegate

	struct Scale {
		static let min: CGFloat = 0.5
		static let max: CGFloat = 17.4
	}

	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		var scale = self.rootNode.scale + CGFloat(rotationalDelta * 2)
		if #available(watchOSApplicationExtension 5.0, *), let crownSequencer = crownSequencer {
			let isHapticFeedbackEnabled = scale < Scale.max && scale > Scale.min
			if crownSequencer.isHapticFeedbackEnabled != isHapticFeedbackEnabled {
				crownSequencer.isHapticFeedbackEnabled = isHapticFeedbackEnabled
				crownSequencer.focus()
			}
		}
		scale = min(Scale.max, max(scale, Scale.min))
		self.rootNode.scale = scale

		self.startInteractionTimer()
	}

	// MARK: MapNodeDelegate

	func updateMoveToUserLocationNode() {
		let mode: FollowingMode
		if self.rootNode.currentLocation == nil {
			mode = .disabled
		} else if self.isTracking {
			mode = .following
		} else {
			mode = .center
		}
		self.moveToUserLocationNode.texture = mode.texture()
		let size = self.scene.frame.size
		let offset: CGFloat = 25
		self.moveToUserLocationNode.position = CGPoint(x: size.width * 0.5 - offset, y: -size.height * 0.5 + offset)
	}

	func cameraScaleDidChange(_ scale: CGFloat) {
		self.camera.setScale(scale)
	}

	func cameraPositionDidChange(_ position: CGPoint, animated: Bool, completion: @escaping () -> Void) {
		self.cameraPosition = position
		if animated {
			self.camera.run(.move(to: position, duration: 0.2)) {
				completion()
			}
		} else {
			self.camera.position = position
			completion()
		}
	}

	// MARK: RouteControllerDelegate

	func didSelectManeuver(_ maneuver: Maneuver) {
		self.popToRootController()
		Analytics.track("WatchAppSelectManeuver")
		self.rootNode.selectedManeuver = maneuver
	}

}

