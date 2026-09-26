require "minitest/autorun"
require "vaultez"

# Stands in for Vaultez::Client so tests never touch the network or the
# local config file.
class FakeClient
  def initialize(secrets: [], token_mode: false)
    @secrets    = secrets
    @token_mode = token_mode
  end

  def project_token_mode? = @token_mode
  def companies           = [{ "id" => 1, "name" => "Test Company", "role" => "owner" }]
  def projects(_id)       = [{ "id" => 2, "name" => "Test Project", "role" => "owner" }]
  def secrets(_id)        = @secrets
end

module CliHelpers
  # Runs `vaultez <args>` in-process and returns [stdout, stderr, exit status].
  def run_cli(*args, secrets: [], token_mode: false)
    client = FakeClient.new(secrets: secrets, token_mode: token_mode)
    status = 0
    out, err = with_client(client) do
      capture_io do
        Vaultez::CLI.start(args)
      rescue SystemExit => e
        status = e.status
      end
    end
    [out, err, status]
  end

  def with_client(client)
    Vaultez::Client.define_singleton_method(:new) { |*| client }
    yield
  ensure
    Vaultez::Client.singleton_class.remove_method(:new)
  end
end

def secret(name, value)
  { "id" => name.hash, "name" => name, "value" => value }
end
