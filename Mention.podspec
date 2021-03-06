#
# Be sure to run `pod lib lint Mention.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Mention"
  s.version          = "0.0.1"
  s.summary          = "@mentions in Swift"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
"A small, efficient library to handle displaying, and composing @mentions, as well as handling when the user taps them. Supports UILabel, UITextField, and UITextView. Why reinvent the wheel?"
                       DESC

  s.homepage         = "https://github.com/BetterWorks/Mention"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Connor Smith" => "cmds4410@gmail.com" }
  s.source           = { :git => "https://github.com/BetterWorks/Mention.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/FlghtOfThCondor'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Mention' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
