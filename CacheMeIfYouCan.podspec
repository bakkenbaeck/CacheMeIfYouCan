Pod::Spec.new do |s|
  s.name             = "CacheMeIfYouCan"
  s.summary          = "Swift Generic Thread Safe Caching"
  s.version          = "0.1"
  s.homepage         = "https://github.com/bakkenbaeck/CacheMeIfYouCan"
  s.license          = 'MIT'
  s.author           = { "Bakken & Bæck" => "ios@bakkenbaeck.com" }
  s.source           = { :git => "https://github.com/bakkenbaeck/CacheMeIfYouCan.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/BakkenBaeck'
  s.ios.deployment_target = '12.0'
  s.swift_version = '4.2'
  s.requires_arc = true
  s.source_files = 'CacheMeIfYouCan/CacheMeIfYouCan/**/*.swift'
end
