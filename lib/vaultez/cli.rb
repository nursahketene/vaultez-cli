require "thor"
require_relative "commands/auth"
require_relative "commands/fetch"
require_relative "commands/config_command"

module Vaultez
  class CLI < Thor
    include Vaultez::Commands::Auth
    include Vaultez::Commands::Fetch
    include Vaultez::Commands::ConfigCommand

    desc "login", "Authenticate with Vaultez"
    long_desc <<~DESC, wrap: false
      Authenticate with your Vaultez account. You will be prompted for your
      email and password. Your session token is stored in ~/.vaultez/config.yml.

      Example:
        vaultez login
    DESC
    def login; super; end

    desc "logout", "Log out and revoke your token"
    long_desc <<~DESC, wrap: false
      Revokes your session token on the server and clears your local credentials.

      Example:
        vaultez logout
    DESC
    def logout; super; end

    desc "fetch", "Fetch companies, projects, or secrets"
    long_desc <<~DESC, wrap: false
      Fetch resources from Vaultez. The --company flag is optional when you
      have a default company set or only belong to one company.

      Examples:
        vaultez fetch --companies
        vaultez fetch --company="Acme" --projects
        vaultez fetch --company="Acme" --project="Backend"
        vaultez fetch --company="Acme" --project="Backend" --secret="DATABASE_URL"
    DESC
    option :companies, type: :boolean, desc: "List all your companies"
    option :company,   type: :string,  desc: "Company name"
    option :projects,  type: :boolean, desc: "List projects in a company"
    option :project,   type: :string,  desc: "Project name"
    option :secret,    type: :string,  desc: "Secret name"
    def fetch; super; end

    desc "config", "Configure Vaultez CLI settings"
    long_desc <<~DESC, wrap: false
      Update your local Vaultez CLI configuration.

      Examples:
        vaultez config --default-company="Acme"
    DESC
    option :"default-company", type: :string, desc: "Set the default company"
    def config; super; end
  end
end
