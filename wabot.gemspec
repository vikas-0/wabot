# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "wabot"
  spec.version       = File.read(File.expand_path("lib/wabot/version.rb", __dir__)).match(/VERSION\s*=\s*"([^"]+)"/)[1]
  spec.authors       = ["Vikas Kumar"]
  spec.email         = ["vikas_kr@live.com"]

  spec.summary       = "WaBot: Personal WhatsApp Web automation with CLI and block-based API"
  spec.description   = "Automate WhatsApp Web from Ruby using Selenium. Provides a CLI and a Ruby API with block-based session handling."
  spec.homepage      = "https://github.com/vikas-0/wabot"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    (Dir["lib/wabot/**/*"] + ["lib/wabot.rb", "bin/wabot", "README.md"] + Dir["LICENSE*"]).select { |f| File.file?(f) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["wabot"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "selenium-webdriver", "~> 4.11"
  spec.add_runtime_dependency "thor", "~> 1.3"
  spec.add_runtime_dependency "colorize", "~> 1.1"
end
