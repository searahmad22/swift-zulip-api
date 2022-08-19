Pod::Spec.new do |s|
  s.name = 'swift-zulip-tjk-api'
  s.version = '0.3.0'
  s.summary = 'A library to access the Zulip API with Swift.'
  s.license = { :type => 'MIT' }
  s.author = { 'Marco Burstein' => 'theskunkmb@gmail.com' }
  s.homepage = 'https://github.com/searahmad22/swift-zulip-api'
  s.source_files = 'sources/SwiftZulipAPI'
  s.source = {
    :git => 'https://github.com/searahmad22/swift-zulip-api.git',
    :tag => '0.3.0'
  }
  s.swift_version = '5.1'

  # These are based on the Alamofire deployment targets.
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.dependency 'Alamofire', '~> 5.6.1'
end
