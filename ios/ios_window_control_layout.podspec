#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ios_window_control_layout.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ios_window_control_layout'
  s.version          = '0.3.0'
  s.summary          = 'Expose iOS window-control-aware layout margins to Flutter.'
  s.description      = <<-DESC
Expose iOS window-control-aware layout margins to Flutter.
                       DESC
  s.homepage         = 'https://github.com/FriesI23/ios_window_control_layout'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Fries_I23'
  s.source           = { :path => '.' }
  s.source_files = 'ios_window_control_layout/Sources/ios_window_control_layout/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
