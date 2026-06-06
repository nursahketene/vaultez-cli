require "net/http"
require "json"
require "uri"

module Vaultez
  class Client
    def initialize
      @api_url = Vaultez::Config.api_url
      @token   = Vaultez::Config.token
    end

    def login(email, password)
      post("/api/v1/auth/login", { email: email, password: password }, authenticated: false)
    end

    def logout
      delete("/api/v1/auth/logout")
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
      http.use_ssl = uri.scheme == "https"

      req = build_request(method, uri)
      req["Content-Type"] = "application/json"
      req["Accept"]       = "application/json"

      if authenticated
        raise Vaultez::NotAuthenticatedError, "Not logged in. Run `vaultez login` first." unless @token
        req["Authorization"] = "Bearer #{@token}"
      end

      req.body = body.to_json if body

      parse_response(http.request(req))
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
      when 401 then raise Vaultez::AuthenticationError, body["error"] || "Authentication failed"
      when 404 then raise Vaultez::NotFoundError,       body["error"] || "Not found"
      else          raise Vaultez::ApiError,            body["error"] || "API error (#{response.code})"
      end
    end
  end
end
