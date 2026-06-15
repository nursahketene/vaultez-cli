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

        puts "One-time code (Proton Authenticator / TOTP): "
        otp_code = $stdin.gets.chomp

        client = Vaultez::Client.new
        response = client.login(email, password, otp_code)

        Vaultez::Config.set("token", response["token"])
        puts "Logged in successfully."
      rescue Vaultez::TwoFactorRequiredError => error
        puts "Error: #{error.message}"
        puts "Set up two-factor authentication at https://vaultez.app/two_factor/new"
        exit 1
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
