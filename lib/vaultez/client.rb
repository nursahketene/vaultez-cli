require "net/http"
require "json"
require "uri"

module Vaultez
  class Client
    # A legitimate response (companies/projects/secrets, all short strings)
    # is a handful of KB at most. This bounds how much of a compromised or
    # malicious response - a compromised API backend, a MITM'd/redirected
    # api_url, or a compromised account crafting an oversized payload - this
    # process will hold in memory, independent of any size limit a caller
    # (e.g. the oma-vaultez plugin) enforces on this CLI's own stdout.
    MAX_RESPONSE_BYTES = 4 * 1024 * 1024

    def initialize
      @api_url       = Vaultez::Config.api_url
      @token         = Vaultez::Config.token
      @project_token = ENV["VAULTEZ_TOKEN"]
    end

    def login(email, password, otp_code)
      post("/api/v1/auth/login", { email: email, password: password, otp_code: otp_code }, authenticated: false)
    end

    def logout
      delete("/api/v1/auth/logout")
    end

    def project_token_mode?
      !@project_token.nil?
    end

    def companies
      get("/api/v1/companies")
    end

    def projects(company_id)
      get("/api/v1/companies/#{company_id}/projects")
    end

    def secrets(project_id)
      get("/api/v1/projects/#{project_id}/secrets")
    end

    private

    def get(path)
      request(:get, path)
    end

    def post(path, body, authenticated: true)
      request(:post, path, body, authenticated: authenticated)
    end

    def delete(path)
      request(:delete, path)
    end

    def request(method, path, body = nil, authenticated: true)
      uri  = URI("#{@api_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 15

      req = build_request(method, uri)
      req["Content-Type"] = "application/json"
      req["Accept"]       = "application/json"

      if authenticated
        active_token = @project_token || @token
        raise Vaultez::NotAuthenticatedError, "Not logged in. Run `vaultez login` first, or set VAULTEZ_TOKEN." unless active_token
        req["Authorization"] = "Bearer #{active_token}"
      end

      req.body = body.to_json if body

      begin
        response = fetch_bounded(http, req)
      rescue Vaultez::Error
        raise
      rescue StandardError => error
        raise Vaultez::ApiError, "Could not reach the Vaultez API: #{error.message}"
      end

      parse_response(response)
    end

    # Reads the response body incrementally instead of Net::HTTP's default
    # #request behavior, which fully buffers the entire body in memory
    # before returning with no size limit at all. Aborts (closing the
    # connection) the moment the body crosses MAX_RESPONSE_BYTES, rather
    # than finishing the download and only noticing afterward.
    def fetch_bounded(http, req)
      response = nil
      body = +""
      http.request(req) do |res|
        response = res
        res.read_body do |chunk|
          body << chunk
          if body.bytesize > MAX_RESPONSE_BYTES
            raise Vaultez::ApiError, "Vaultez API response exceeded the maximum allowed size"
          end
        end
      end
      response.body = body
      response
    end

    def build_request(method, uri)
      case method
      when :get    then Net::HTTP::Get.new(uri)
      when :post   then Net::HTTP::Post.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      end
    end

    def parse_response(response)
      body = JSON.parse(response.body) rescue {}

      case response.code.to_i
      when 200, 201 then body
      when 401 then raise Vaultez::AuthenticationError,    body["error"] || "Authentication failed"
      when 403 then raise Vaultez::TwoFactorRequiredError, body["error"] || "Two-factor authentication required"
      when 404 then raise Vaultez::NotFoundError,          body["error"] || "Not found"
      else          raise Vaultez::ApiError,               body["error"] || "API error (#{response.code})"
      end
    end
  end
end
