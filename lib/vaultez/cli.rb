require "thor"
require_relative "version"
require_relative "commands/auth"
require_relative "commands/fetch"
require_relative "commands/config_command"

module Vaultez
  class CLI < Thor
    include Vaultez::Commands::Auth
    include Vaultez::Commands::Fetch
    include Vaultez::Commands::ConfigCommand

    map %w[--version -v] => :__version

    desc "login", "Authenticate with email, password, and 2FA code"
    long_desc <<~DESC, wrap: false
      Authenticate with your Vaultez account. You will be prompted for your
      email, password, and a two-factor authentication code from your authenticator
      app (or a backup code). Your session token is stored in ~/.vaultez/config.yml.

      Two-factor authentication is required for all accounts.

      Example:
        vaultez login
    DESC
    def login; super; end

    desc "logout", "Revoke the current session token"
    long_desc <<~DESC, wrap: false
      Revokes your session token on the server and clears your local credentials.

      Example:
        vaultez logout
    DESC
    def logout; super; end

    desc "fetch", "Fetch secrets from a project"
    long_desc <<~DESC, wrap: false
      Fetch resources from Vaultez.

      USER SESSION (after `vaultez login`):
        The --company flag is optional when you have a default company set or
        only belong to one company. Use --project to scope to a project.

        vaultez fetch --companies
        vaultez fetch --company="Acme" --projects
        vaultez fetch --company="Acme" --project="Backend"
        vaultez fetch --company="Acme" --project="Backend" --secret="DATABASE_URL"

      PROJECT TOKEN (VAULTEZ_TOKEN env var):
        When a project token is active, it already knows which project to use.
        No --project flag is needed.

        VAULTEZ_TOKEN=vz_... vaultez fetch
        VAULTEZ_TOKEN=vz_... vaultez fetch --secret="DATABASE_URL"

      Project tokens can be created in the Tokens tab of your project settings.
      Always pass the token via the VAULTEZ_TOKEN environment variable, never
      as a command-line flag — CLI arguments are visible to other local users
      via `ps` and get saved in shell history.
    DESC
    option :companies, type: :boolean, desc: "List all your companies"
    option :company,   type: :string,  desc: "Company name"
    option :projects,  type: :boolean, desc: "List projects in a company"
    option :project,   type: :string,  desc: "Project name"
    option :secret,    type: :string,  desc: "Secret name (returns value only)"
    option :json,      type: :boolean, desc: "Output as JSON (errors go to stderr)"
    def fetch; super; end

    desc "config", "Set default company or token"
    long_desc <<~DESC, wrap: false
      Update your local Vaultez CLI configuration.

      Examples:
        vaultez config --default-company="Acme"
    DESC
    option :"default-company", type: :string, desc: "Set the default company"
    def config; super; end

    desc "__version", "Show the installed CLI version", hide: true
    def __version
      puts "vaultez-cli #{Vaultez::VERSION}"
    end

    def help(command = nil, subcommand: false)
      if command
        super
      else
        puts "Vaultez CLI — secure secret management from your terminal"
        puts
        puts "Usage: vaultez <command> [options]"
        puts
        puts "Commands:"
        puts "  login       Authenticate with email, password, and 2FA code"
        puts "  logout      Revoke the current session token"
        puts "  fetch       Fetch secrets from a project"
        puts "  config      Set default company or token"
        puts "  help        Show help for any command"
        puts
        puts "Options:"
        puts "  --version   Show the installed CLI version"
        puts
        puts "Examples:"
        puts "  vaultez login"
        puts "  vaultez fetch --project=\"Backend\""
        puts "  vaultez fetch --project=\"Backend\" --secret=\"DATABASE_URL\""
        puts "  VAULTEZ_TOKEN=\"vz_...\" vaultez fetch"
        puts "  VAULTEZ_TOKEN=\"vz_...\" vaultez fetch --secret=\"DATABASE_URL\""
      end
    end
  end
end
