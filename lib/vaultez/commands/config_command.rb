module Vaultez
  module Commands
    module ConfigCommand
      def config
        if options[:"default-company"]
          client    = Vaultez::Client.new
          companies = client.companies
          company   = companies.find { |company| company["name"] == options[:"default-company"] }

          unless company
            puts "Error: company \"#{options[:"default-company"]}\" not found."
            exit 1
          end

          Vaultez::Config.set("default_company", company["name"])
          puts "Default company set to \"#{company["name"]}\"."
        else
          puts "No config option provided. See `vaultez help config`."
          exit 1
        end
      rescue Vaultez::NotAuthenticatedError => error
        puts "Error: #{error.message}"
        exit 1
      rescue Vaultez::ApiError => error
        puts "Error: #{error.message}"
        exit 1
      end
    end
  end
end
