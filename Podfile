platform :ios, '9.0'
use_modular_headers!
source 'https://github.com/CocoaPods/Specs.git'

def import_watch;                   pod 'VNWatch',              :path => 'Watch';                       end

target 'DemoWatch' do
	import_watch
end

target 'WatchExtension' do
	project 'DemoWatch.xcodeproj'
	platform :watchos, '3.0'
	import_watch
end
