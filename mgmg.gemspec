
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mgmg/version"

Gem::Specification.new do |spec|
  spec.name          = "mgmg"
  spec.version       = Mgmg::VERSION
  spec.authors       = ["KAZOON"]
  spec.email         = ["cycloawaodorin+gem@gmail.com"]

  spec.summary       = %q{Calculate specs of equipments of Megurimeguru, a game produced by Kou.}
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/cycloawaodorin/"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/cycloawaodorin/mgmg"
    spec.metadata["changelog_uri"] = "https://github.com/cycloawaodorin/mgmg/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 2.3.16"
  spec.add_development_dependency "rake", ">= 13.0.6"
  spec.add_development_dependency "irb", ">= 1.4.1"
  
  spec.required_ruby_version = '>= 3.1.0'
end
