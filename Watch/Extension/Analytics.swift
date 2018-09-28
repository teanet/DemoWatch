import WatchKit
import WatchConnectivity
import VNWatch

internal final class Analytics {

	internal static let shared = Analytics()
	private let session: WCSession
	private let ud: UserDefaults
	private weak var timer: Timer?
	private let lockQueue = DispatchQueue(label: "ru.doublegis.grymmobile.watch.analytics")

	private init() {
		self.session = WCSession.default
		self.ud = UserDefaults.standard
	}

	static func track(_ name: String, value: String? = nil) {
		self.shared.track(name, value: value)
	}

	internal func track(_ name: String, value: String? = nil) {
		self.lockQueue.async {
			var events = self.ud.events
			events += [ WatchEvent(name: name, value: value) ]
			self.ud.events = events
		}
		self.scheduleSync()
	}

	internal func scheduleSync() {
		self.timer?.invalidate()
		self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.sync), userInfo: nil, repeats: false)
	}

	@objc private func sync() {
		guard self.session.activationState == .activated else { return }

		self.lockQueue.async {

			let events = self.ud.events
			let scheduledEvents = self.ud.scheduledEvents + events
			self.ud.scheduledEvents = scheduledEvents
			self.ud.events = []

			if let data = try? JSONEncoder().encode(scheduledEvents) {
				self.session.sendMessageData(data, replyHandler: { (response) in

					self.lockQueue.async {
						self.ud.scheduledEvents = []
					}
				}, errorHandler: nil)
			}
		}
	}

}

public extension UserDefaults {

	public var events: [WatchEvent] {
		get {
			guard let data = self.data(forKey: "analytics"),
				let events = try? JSONDecoder().decode([WatchEvent].self, from: data) else { return [] }
			return events
		}
		set {
			let data = try? JSONEncoder().encode(newValue)
			self.set(data, forKey: "analytics")
			self.synchronize()
		}
	}

	public var scheduledEvents: [WatchEvent] {
		get {
			guard let data = self.data(forKey: "scheduledEvents"),
				let events = try? JSONDecoder().decode([WatchEvent].self, from: data) else { return [] }
			return events
		}
		set {
			let data = try? JSONEncoder().encode(newValue)
			self.set(data, forKey: "scheduledEvents")
			self.synchronize()
		}
	}

}

