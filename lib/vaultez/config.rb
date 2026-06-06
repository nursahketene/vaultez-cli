require "yaml"
require "fileutils"

module Vaultez
  class Config
    CONFIG_PATH = File.expand_path("~/.vaultez/config.yml")

    def self.get(key)
      read[key.to_s]
    end

    def self.set(key, value)
      data = read
      data[key.to_s] = value
      write(data)
    end

    def self.delete(key)
      data = read
      data.delete(key.to_s)
      write(data)
    end

    def self.clear
      FileUtils.rm_f(CONFIG_PATH)
    end

    def self.token
      get("token")
    end

    def self.api_url
      get("api_url") || "https://vaultez.app"
    end

    def self.default_company
      get("default_company")
    end

    private

    def self.read
      return {} unless File.exist?(CONFIG_PATH)
      YAML.safe_load(File.read(CONFIG_PATH)) || {}
    end

    def self.write(data)
      FileUtils.mkdir_p(File.dirname(CONFIG_PATH))
      File.write(CONFIG_PATH, data.to_yaml)
    end
  end
end
