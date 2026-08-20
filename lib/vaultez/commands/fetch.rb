require "json"

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

      def fail!(message)
        if options[:json]
          warn "Error: #{message}"
        else
          puts "Error: #{message}"
        end
        exit 1
      end

      def fetch_with_project_token(client)
        if options[:secret]
          secrets = fetch_all_secrets_for_token(client)
          secret  = secrets.find { |s| s["name"] == options[:secret] }
          unless secret
            fail!("secret \"#{options[:secret]}\" not found.")
          end
          if options[:json]
            puts secret.to_json
          else
            print secret["value"]
          end
        else
          secrets = fetch_all_secrets_for_token(client)
          if options[:json]
            puts secrets.to_json
            return
          end
          if secrets.empty?
            puts "No secrets found."
            return
          end
          secrets.each { |s| puts "#{s["name"]}=#{s["value"]}" }
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
        if options[:json]
          puts companies.to_json
          return
        end
        if companies.empty?
          puts "No companies found."
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
        if options[:json]
          puts projects.to_json
          return
        end
        if projects.empty?
          puts "No projects found in #{company["name"]}."
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
        if options[:json]
          puts secrets.to_json
          return
        end
        if secrets.empty?
          puts "No secrets found in #{project["name"]}."
          return
        end
        secrets.each do |secret|
          puts "#{secret["name"]}=#{secret["value"]}"
        end
      end

      def fetch_secret(client)
        company = resolve_company(client)
        project = resolve_project(client, company)
        secrets = client.secrets(project["id"])
        secret  = secrets.find { |s| s["name"] == options[:secret] }

        unless secret
          fail!("secret \"#{options[:secret]}\" not found in #{project["name"]}.")
        end

        if options[:json]
          puts secret.to_json
        else
          print secret["value"]
        end
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
