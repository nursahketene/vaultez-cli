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
      ENV["VAULTEZ_TOKEN"] || get("token")
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
      tighten_permissions
      YAML.safe_load(File.read(CONFIG_PATH)) || {}
    end

    def self.write(data)
      dir = File.dirname(CONFIG_PATH)
      FileUtils.mkdir_p(dir, mode: 0o700)
      # The mode argument to mkdir_p/File.open only applies at creation time,
      # so explicitly chmod too - this also retroactively tightens a config
      # directory/file that was created before this fix, which would
      # otherwise stay world-readable forever (0644/0755 by default umask).
      File.chmod(0o700, dir)
      File.open(CONFIG_PATH, File::CREAT | File::TRUNC | File::WRONLY, 0o600) do |f|
        f.write(data.to_yaml)
      end
      File.chmod(0o600, CONFIG_PATH)
    end

    def self.tighten_permissions
      dir = File.dirname(CONFIG_PATH)
      File.chmod(0o700, dir) if File.directory?(dir) && (File.stat(dir).mode & 0o777) != 0o700
      File.chmod(0o600, CONFIG_PATH) if (File.stat(CONFIG_PATH).mode & 0o777) != 0o600
    rescue StandardError
      nil # best-effort; never block a read over a permissions fix
    end
  end
end
