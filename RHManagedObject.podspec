Pod::Spec.new do |s|
  s.name             = "RHManagedObject"
  s.version          = "0.17"
  s.summary          = "RHManagedObject is a library for iOS to simplify your life with Core Data."
  s.homepage         = "https://github.com/chriscdn/RHManagedObject"
  s.license          = 'MIT'
  s.author           = { "Christopher Meyer" => "chris@rhouse.ch" }
  s.source           = { :git => "https://github.com/chriscdn/RHManagedObject.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/chriscdn'

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source_files = 'RHManagedObject/*'

end