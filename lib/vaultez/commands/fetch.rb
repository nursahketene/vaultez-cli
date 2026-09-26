require "json"
require_relative "../output"

module Vaultez
  module Commands
    module Fetch
      def fetch
        client = Vaultez::Client.new

        if client.project_token_mode?
          fetch_with_project_token(client)
        elsif options[:companies]
          fetch_companies(client)
        elsif options[:projects]
          fetch_projects(client)
        elsif options[:project] && options[:secret]
          fetch_secret(client)
        elsif options[:project]
          fetch_secrets(client)
        else
          fail!("not enough options. See `vaultez help fetch`.")
        end
      rescue Vaultez::NotAuthenticatedError => error
        fail!(error.message)
      rescue Vaultez::NotFoundError => error
        fail!(error.message)
      rescue Vaultez::ApiError => error
        fail!(error.message)
      end

      private

      # Stdout carries only data, so `vaultez fetch > .env` never writes an
      # error or a notice into the file. Everything else goes to stderr.
      def fail!(message)
        warn "Error: #{message}"
        exit 1
      end

      def output_format
        @output_format ||= begin
          format = options[:format]
          if options[:json] && format && format != "json"
            fail!("--json can't be combined with --format=#{format}.")
          end
          format || (options[:json] ? "json" : Vaultez::Output::DEFAULT_FORMAT)
        end
      end

      def json?
        output_format == "json"
      end

      def print_secret_value(secret)
        if json?
          puts secret.to_json
        else
          print secret["value"]
        end
      end

      def print_secrets(secrets, empty_message)
        warn empty_message if secrets.empty?
        text, warnings = Vaultez::Output.render(secrets, output_format)
        print text
        warnings.each { |message| warn "Warning: #{message}" }
      end

      def fetch_with_project_token(client)
        if options[:secret]
          secrets = fetch_all_secrets_for_token(client)
          secret  = secrets.find { |s| s["name"] == options[:secret] }
          unless secret
            fail!("secret \"#{options[:secret]}\" not found.")
          end
          print_secret_value(secret)
        else
          print_secrets(fetch_all_secrets_for_token(client), "No secrets found.")
        end
      end

      def fetch_all_secrets_for_token(client)
        companies = client.companies
        company   = companies.first
        unless company
          fail!("no company found for this token.")
        end
        projects = client.projects(company["id"])
        project  = projects.first
        unless project
          fail!("no project found for this token.")
        end
        client.secrets(project["id"])
      end

      def fetch_companies(client)
        companies = client.companies
        if json?
          puts companies.to_json
          return
        end
        if companies.empty?
          warn "No companies found."
          return
        end
        puts "Companies:"
        companies.each do |company|
          puts "  #{company["name"]} (#{company["role"]})"
        end
      end

      def fetch_projects(client)
        company  = resolve_company(client)
        projects = client.projects(company["id"])
        if json?
          puts projects.to_json
          return
        end
        if projects.empty?
          warn "No projects found in #{company["name"]}."
          return
        end
        puts "Projects in #{company["name"]}:"
        projects.each do |project|
          puts "  #{project["name"]} (#{project["role"]})"
        end
      end

      def fetch_secrets(client)
        company = resolve_company(client)
        project = resolve_project(client, company)
        secrets = client.secrets(project["id"])
        print_secrets(secrets, "No secrets found in #{project["name"]}.")
      end

      def fetch_secret(client)
        company = resolve_company(client)
        project = resolve_project(client, company)
        secrets = client.secrets(project["id"])
        secret  = secrets.find { |s| s["name"] == options[:secret] }

        unless secret
          fail!("secret \"#{options[:secret]}\" not found in #{project["name"]}.")
        end

        print_secret_value(secret)
      end

      def resolve_company(client)
        companies = client.companies

        if options[:company]
          company = companies.find { |c| c["name"] == options[:company] }
          unless company
            fail!("company \"#{options[:company]}\" not found.")
          end
          return company
        end

        default_name = Vaultez::Config.default_company
        if default_name
          company = companies.find { |c| c["name"] == default_name }
          return company if company
        end

        return companies.first if companies.size == 1

        fail!("multiple companies found. Specify one with --company or set a default with `vaultez config --default-company`.")
      end

      def resolve_project(client, company)
        projects = client.projects(company["id"])
        project  = projects.find { |p| p["name"] == options[:project] }
        unless project
          fail!("project \"#{options[:project]}\" not found in #{company["name"]}.")
        end
        project
      end
    end
  end
end
