import Foundation

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence

extension Int {

	static func ^^ (radix: Int, power: Int) -> Int {
		return Int(pow(Double(radix), Double(power)))
	}

}
