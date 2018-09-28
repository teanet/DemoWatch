import Foundation

public enum WatchModel {
	case series0
	case series1
	case series2
	case series3
	case other

	static let current: WatchModel = {
		var size: size_t = 0
		sysctlbyname("hw.machine", nil, &size, nil, 0)
		var machine = CChar()
		sysctlbyname("hw.machine", &machine, &size, nil, 0)

		guard let model = String(cString: &machine, encoding: String.Encoding.utf8) else { return .other }
		switch model {
			case "Watch1,1": return .series0
			case "Watch1,2": return .series0
			case "Watch2,3": return .series2
			case "Watch2,4": return .series2
			case "Watch2,6": return .series1
			case "Watch2,7": return .series1
			case "Watch3,1": return .series3
			case "Watch3,2": return .series3
			case "Watch3,3": return .series3
			case "Watch3,4": return .series3
			default: return .other
		}
	}()

}
