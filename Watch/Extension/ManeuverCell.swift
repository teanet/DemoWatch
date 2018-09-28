import WatchKit
import VNWatch

public final class ManeuverCell: NSObject {
	@IBOutlet public private(set) var titleLabel: WKInterfaceLabel!
	@IBOutlet public private(set) var subtitleLabel: WKInterfaceLabel!
	@IBOutlet public private(set) var image: WKInterfaceImage!
	@IBOutlet public private(set) var background: WKInterfaceGroup!

	func update(with maneuver: Maneuver) {
		self.titleLabel.setText(maneuver.outcomingPathComment)
		self.subtitleLabel.setText(maneuver.comment)
		self.image.setImage(maneuver.image)
	}

}

