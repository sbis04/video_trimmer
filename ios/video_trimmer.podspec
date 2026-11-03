Pod::Spec.new do |s|
  s.name             = 'video_trimmer'
  s.version          = '6.0.0'
  s.summary          = 'Native thumbnails and trimming for the video_trimmer Flutter package.'
  s.description      = <<-DESC
Extracts JPEG frames for the video_trimmer trim viewer and trims videos with AVFoundation.
                       DESC
  s.homepage         = 'https://github.com/sbis04/video_trimmer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Souvik Biswas' => 'sbis1999@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'video_trimmer/Sources/video_trimmer/**/*.swift'
  s.resource_bundles = { 'video_trimmer_privacy' => ['video_trimmer/Sources/video_trimmer/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.frameworks       = 'AVFoundation'
  s.platform         = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
