# This is copied over into the Eigen root
# during beta deployment

source 'https://rubygems.org'

gem 'fastlane'
gem 'cocoapods'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval(File.read(plugins_path), binding) if File.exist?(plugins_path)
