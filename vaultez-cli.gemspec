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

  # Pinned exact, not "~> 1.0": an unpinned range would let gem install
  # resolve whatever the latest matching thor release happens to be at
  # install time, with no re-review, the same class of issue already fixed
  # for this gem's own version pin. 1.5.0 is what's actually been installed
  # and tested throughout this gem's own development.
  spec.add_dependency "thor", "1.5.0"
end
