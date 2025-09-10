# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "whatsapp_web_personal"
  spec.version       = File.read(File.expand_path("lib/whatsapp_bot/version.rb", __dir__)).match(/VERSION\s*=\s*"([^"]+)"/)[1]
  spec.authors       = ["Vikas Kumar"]
  spec.email         = ["vikas_kr@live.com"]

  spec.summary       = "Personal WhatsApp Web bot with CLI and block-based API"
  spec.description   = "Automate WhatsApp Web from Ruby using Selenium. Provides a CLI and a Ruby API with block-based session handling."
  spec.homepage      = "https://github.com/vikas-0/whatsapp_bot_ruby"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "bin/*", "README.md", "LICENSE*"].select { |f| File.file?(f) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["wawp"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "selenium-webdriver", "~> 4.11"
  spec.add_runtime_dependency "thor", "~> 1.3"
  spec.add_runtime_dependency "bcrypt", "~> 3.1"
  spec.add_runtime_dependency "colorize", "~> 1.1"
end
