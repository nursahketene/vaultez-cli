module Vaultez
  module Commands
    module Fetch
      def fetch
        client = Vaultez::Client.new

        if options[:companies]
          fetch_companies(client)
        elsif options[:projects]
          fetch_projects(client)
        elsif options[:project] && options[:secret]
          fetch_secret(client)
        elsif options[:project]
          fetch_secrets(client)
        else
          puts "Error: not enough options. See `vaultez help fetch`."
          exit 1
        end
      rescue Vaultez::NotAuthenticatedError => error
        puts "Error: #{error.message}"
        exit 1
      rescue Vaultez::NotFoundError => error
        puts "Error: #{error.message}"
        exit 1
      rescue Vaultez::ApiError => error
        puts "Error: #{error.message}"
        exit 1
      end

      private

      def fetch_companies(client)
        companies = client.companies
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
        secret  = secrets.find { |secret| secret["name"] == options[:secret] }

        unless secret
          puts "Error: secret \"#{options[:secret]}\" not found in #{project["name"]}."
          exit 1
        end

        print secret["value"]
      end

      def resolve_company(client)
        companies = client.companies

        if options[:company]
          company = companies.find { |company| company["name"] == options[:company] }
          unless company
            puts "Error: company \"#{options[:company]}\" not found."
            exit 1
          end
          return company
        end

        default_name = Vaultez::Config.default_company
        if default_name
          company = companies.find { |company| company["name"] == default_name }
          return company if company
        end

        if companies.size == 1
          return companies.first
        end

        puts "Error: multiple companies found. Specify one with --company or set a default with `vaultez config --default-company`."
        exit 1
      end

      def resolve_project(client, company)
        projects = client.projects(company["id"])
        project  = projects.find { |project| project["name"] == options[:project] }
        unless project
          puts "Error: project \"#{options[:project]}\" not found in #{company["name"]}."
          exit 1
        end
        project
      end
    end
  end
end
