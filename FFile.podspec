Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "FFile"
s.summary = "Auto save File with AWS S3"
s.requires_arc = true

# 2
s.version = "0.1.9"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Muqq" => "bbbb55952000@gmail.com" }


# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "http://github.com/Invisibi/FFile"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/Invisibi/FFile.git", :tag => "#{s.version}"}

# 7
s.framework = "Foundation"
s.framework = "MobileCoreServices"
s.dependency 'AWSCore', '2.4.7'
s.dependency 'AWSS3', '2.4.7'
s.dependency 'SPTPersistentCache'

# 8
s.source_files = "FFile/**/*"
end
