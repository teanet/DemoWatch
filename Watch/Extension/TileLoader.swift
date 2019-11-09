import Foundation
import WatchKit
import SpriteKit

final class TileLoader: NSObject, URLSessionDataDelegate {

	private lazy var session: URLSession = { [unowned self] in
		let configuration = URLSessionConfiguration.default
		configuration.allowsCellularAccess = true
		configuration.requestCachePolicy = .returnCacheDataElseLoad
		configuration.urlCache = URLCache(memoryCapacity: 5 * 1024 * 1024, diskCapacity: 30 * 1024 * 1024, diskPath: nil)
		return URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
	}()
	private let cache = NSCache<NSURL, SKTexture>()
	private var loadingTiles = [LoadingTile]()
	private let lockQueue = DispatchQueue(label: "ru.doublegis.grymmobile.watch")
	private var singleTileLoaded = false

	override init() {
		super.init()
		self.cache.countLimit = 70
	}

	func cancel(for path: TilePath) {
		self.lockQueue.async {
			self.loadingTiles.remove(path)
		}
	}

	public subscript(path: TilePath) -> SKTexture? {
		let url = path.url()
		return self.cache.object(forKey: url as NSURL)
	}

	typealias ResultBlock = (Result, TilePath) -> Void
	func loadTile(at path: TilePath, priority: Float, callbackQueue: DispatchQueue = .main, result: @escaping ResultBlock) {

		let completion: ResultBlock = { r, tp in
			callbackQueue.async {
				result(r, tp)
			}
		}

		guard path.isValid else {
			completion(.error, path)
			return
		}

		let url = path.url()
		if let texture = self.cache.object(forKey: url as NSURL) {
			completion(.texture(texture), path)
			return
		}

		if let loading = self.loadingTiles.first(where: { $0.tile == path }) {
			loading.task.priority = priority
			return
		}

		if self.loadingTiles.count > 8 {
			self.lockQueue.async {
				self.loadingTiles.removeFirstAndCancel()
			}
		}

		if let image = UIImage(named: path.imageName()) {
			let texture = SKTexture(image: image)
			self.cache.setObject(texture, forKey: url as NSURL)
			completion(.texture(texture), path)
			return
		}

		let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 5)
		let task = self.session.dataTask(with: request) { [weak self] (data, _, error) in
			guard let this = self else { return }

			if let data = data, let image = UIImage(data: data) {
				print("loadTileDone: \(path)", data.count)
				let texture = SKTexture(image: image)
				this.cache.setObject(texture, forKey: url as NSURL)

				if !this.singleTileLoaded {
					this.singleTileLoaded = true
					Analytics.shared.track("WatchAppTileLoaded")
				}
				completion(.texture(texture), path)
			} else {
				print("loadTileFail: \(path)", error?.localizedDescription ?? "")
				completion(.error, path)
			}

			this.lockQueue.async {
				this.loadingTiles.remove(path)
			}
		}
		self.lockQueue.async {
			self.loadingTiles.append(LoadingTile(tile: path, task: task))
		}
		print("loadTile: \(path)", self.loadingTiles.count)
		task.priority = priority
		task.resume()
	}

	struct LoadingTile {
		let tile: TilePath
		let task: URLSessionDataTask
	}

}

extension Array where Element == TileLoader.LoadingTile {

	func has(_ tile: TilePath) -> Bool {
		return self.contains { $0.tile == tile }
	}

	mutating func remove(_ tile: TilePath) {
		if let index = self.firstIndex(where: { $0.tile == tile }) {
			let loadingTile = self.remove(at: index)
			loadingTile.task.cancel()
		}
	}

	mutating func removeFirstAndCancel() {
		let loadingTile = self.removeFirst()
		loadingTile.task.cancel()
	}

}
