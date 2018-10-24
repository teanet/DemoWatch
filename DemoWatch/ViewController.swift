import CoreLocation
import SpriteKit
import WatchKit
import WatchConnectivity
import UIKit
import VNWatch

final class ViewController: UIViewController, WCSessionDelegate, CLLocationManagerDelegate {

	private lazy var lm = CLLocationManager()

	override func viewDidLoad() {
		super.viewDidLoad()

		WCSession.default.delegate = self
		WCSession.default.activate()

		let segmentedControl = UISegmentedControl(items: ["None", "Point", "Route1", "Route2"])
		segmentedControl.selectedSegmentIndex = 0
		segmentedControl.addTarget(self, action: #selector(self.change(_:)), for: .valueChanged)
		self.navigationItem.titleView = segmentedControl

		self.lm.delegate = self
		self.lm.requestWhenInUseAuthorization()
	}

	@objc func change(_ sc: UISegmentedControl) {
		switch sc.selectedSegmentIndex {
			case 0:
				self.update([:])
			case 1:
				self.update(["coordinate":[54.863321, 83.18651]])
			case 2:
				self.updateRoute(with: "Route")
			case 3:
				self.updateRoute(with: "Route1")
			default: break
		}

	}

	func updateRoute(with filename: String) {
		if let url = Bundle.main.url(forResource: filename, withExtension: "json"),
			let data = try? Data.init(contentsOf: url, options: []) {
			self.update(["route" : data])
		}
	}

	func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
		print("userInfoTransfer>>>>>\(userInfoTransfer)", userInfoTransfer.userInfo)
	}

	@available(iOS 9.3, *)
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("activationDidCompleteWith>>>>>\(activationState)", error as Any)
	}

	func update(_ ctx: [String: Any]) {
		guard #available(iOS 9.3, *), WCSession.default.activationState == .activated else {
			return
		}
		do {
			try WCSession.default.updateApplicationContext(ctx)
		} catch {
			print(">>>>>\(error)")
		}
	}

	func sessionWatchStateDidChange(_ session: WCSession) {
	}

	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		print("didReceiveApplicationContext>>>>>\(applicationContext)")
	}

	func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
		if let message = try? JSONDecoder().decode([WatchEvent].self, from: messageData) {
			replyHandler(Data())
			print(">>>>>\(message)")
		}
	}

	func sessionDidBecomeInactive(_ session: WCSession) {
		print("sessionDidBecomeInactive>>>>>")
	}

	func sessionDidDeactivate(_ session: WCSession) {
		print("sessionDidDeactivate>>>>>")
	}

	// MARK: CLLocationManagerDelegate

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("didUpdateLocations>>>>>\(locations)")
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		print("didChangeAuthorization>>>>>\(status.rawValue)")
		if status == .authorizedAlways || status == .authorizedWhenInUse {
			manager.startUpdatingLocation()
		}
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("didFailWithError>>>>>\(error)")
	}

}

