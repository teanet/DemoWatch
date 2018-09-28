import WatchKit
import VNWatch

struct RouteControllerContext {
	let route: Route
	let selectedManeuver: Maneuver?
	let delegate: RouteControllerDelegate
}

protocol RouteControllerDelegate: AnyObject {
	func didSelectManeuver(_ maneuver: Maneuver)
}

internal final class RouteController: WKInterfaceController {

	private var route: Route!
	private var selectedManeuver: Maneuver?
	private weak var delegate: RouteControllerDelegate?

	@IBOutlet var table: WKInterfaceTable!

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		let ctx = (context as! RouteControllerContext)
		self.route = ctx.route
		self.delegate = ctx.delegate
		self.selectedManeuver = ctx.selectedManeuver
	}

	override func didAppear() {
		super.didAppear()
		self.table.setNumberOfRows(self.route.maneuvers.count, withRowType: "ManeuverCell")
		if self.selectedManeuver != nil,
			let index = self.route.maneuvers.index(where: { $0.id == self.selectedManeuver?.id }) {
			self.table.scrollToRow(at: index)
			let group = (self.table.rowController(at: index) as! ManeuverCell).background
			group?.setBackgroundColor(.lightGray)
		}

		for (row, maneuver) in self.route.maneuvers.enumerated() {
			let cell = self.table.rowController(at: row) as! ManeuverCell
			cell.update(with: maneuver)
		}
	}

	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		let maneuver = self.route.maneuvers[rowIndex]
		self.delegate?.didSelectManeuver(maneuver)
	}

}

