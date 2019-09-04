#!/usr/bin/ruby

# require 'puppet'
require 'puppet_forge'
require 'puppet-strings'
require 'puppet-strings/yard'
require 'puppet-strings/json'
require 'rest-client'

release_slug = ENV['SLUG']
release_tarball = release_slug + ".tar.gz"
dest_dir = File.dirname(__dir__)
tmp_dir = File.dirname(__dir__) + "/tmp"
output_json = File.join(__dir__, 'output.json')
endpoint = ENV['ENDPOINT']


unless Dir.exist?(dest_dir)
  # Fetch Release information from API
  # @raise Faraday::ResourceNotFound error if the given release does not exist
  release = PuppetForge::Release.find release_slug

  # Download the Release tarball
  # @raise PuppetForge::ReleaseNotFound error if the given release does not exist
  release.download(Pathname(release_tarball))

  # Verify the MD5
  # @raise PuppetForge::V3::Release::ChecksumMismatch error if the file's md5 does not match the API information
  release.verify(Pathname(release_tarball))

  # Unpack the files to a given directory
  # @raise RuntimeError if it fails to extract the contents of the release tarball
  PuppetForge::Unpacker.unpack(release_tarball, dest_dir, tmp_dir)
end

def self.setup_yard!
  unless @yard_setup # rubocop:disable Style/GuardClause
    ::PuppetStrings::Yard.setup!
    @yard_setup = true
  end
end

def generate(path, output_file)

  setup_yard!

  search_patterns = PuppetStrings::DEFAULT_SEARCH_PATTERNS.map { |pattern| File.join(path, pattern) }

  # Format the arguments to YARD
  args = ['doc']
  args << '--no-output'
  args << '--quiet'
  args << '--no-stats'
  args << '--no-progress'
  args << '--no-save'
  args << '--api public'
  args << '--api private'
  args << '--no-api'
  args += search_patterns

  # Run YARD
  ::YARD::CLI::Yardoc.run(*args)

  ::PuppetStrings::Json.render(output_file)
end

def payload(input_file,uri)
  response = RestClient.post uri, File.read(input_file), :content_type => 'application/json'
  repsonse.code
end

generate(dest_dir, output_json)

payload(output_json,endpoint)

