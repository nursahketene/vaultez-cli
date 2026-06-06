require_relative "lib/vaultez/version"

Gem::Specification.new do |spec|
  spec.name          = "vaultez-cli"
  spec.version       = Vaultez::VERSION
  spec.authors       = ["Nur Ketene"]
  spec.email         = ["nur@vaultez.app"]
  spec.summary       = "CLI tool for Vaultez — manage your secrets from the terminal"
  spec.homepage      = "https://vaultez.app"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files         = Dir["lib/**/*", "bin/*"]
  spec.executables   = ["vaultez"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
end
