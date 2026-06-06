module Vaultez
  module Commands
    module Auth
      def login
        puts "Email: "
        email = $stdin.gets.chomp

        puts "Password: "
        system("stty -echo")
        password = $stdin.gets.chomp
        system("stty echo")
        puts

        client = Vaultez::Client.new
        response = client.login(email, password)

        Vaultez::Config.set("token", response["token"])
        puts "Logged in successfully."
      rescue Vaultez::AuthenticationError => error
        puts "Error: #{error.message}"
        exit 1
      end

      def logout
        client = Vaultez::Client.new
        client.logout
        Vaultez::Config.clear
        puts "Logged out successfully."
      rescue Vaultez::NotAuthenticatedError => error
        puts "Error: #{error.message}"
        exit 1
      end
    end
  end
end
