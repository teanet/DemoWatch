Pod::Spec.new do |s|
  s.name                   = "VNWatch"
  s.version                = "0.0.1"
  s.summary                = "VNWatch."
  s.description            = "Descr"
  s.homepage               = "http://EXAMPLE/VNWatch"
  s.license                = "MIT"
  s.author                 = { "e.tyutyuev" => "e.tyutyuev@2gis.ru" }
  s.platforms              = { "watchos": "3.0", "watchsimulator": "3.0", "ios": "9.0" }
  s.source                 = { :git => "http://2gis.ru/VNWatch.git", :tag => "#{s.version}" }
  s.requires_arc           = true

  s.ios.deployment_target  = '9.0'
  s.watchos.deployment_target = '3.0'
  s.source_files           = "Src", "Src/**/*.{h,m,swift}"
  s.watchos.frameworks     = 'Foundation', 'WatchKit', 'CoreLocation'
  s.ios.frameworks         = 'Foundation', 'CoreLocation'

end
