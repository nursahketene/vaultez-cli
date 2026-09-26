require "json"
require "securerandom"

module Vaultez
  # Renders a project's secrets for the formats `vaultez fetch --format=...`
  # accepts. Every format except json must be safe to hand to its consumer
  # as-is: a secret value is data written by any project editor, so it must
  # never be able to run a command, end its own line early, or set a second
  # variable on the machine of whoever sources the output.
  module Output
    FORMATS        = %w[env shell dotenv github json].freeze
    DEFAULT_FORMAT = "env".freeze

    VARIABLE_NAME = /\A[A-Za-z_][A-Za-z0-9_]*\z/

    module_function

    def valid_name?(name)
      name.is_a?(String) && VARIABLE_NAME.match?(name)
    end

    # Returns [text, warnings]; the caller prints the warnings on stderr.
    # Secrets whose names can't be variable names are left out of the
    # non-json formats, since no shell or dotenv parser would accept the line.
    def render(secrets, format)
      return [JSON.generate(secrets) + "\n", []] if format == "json"

      warnings = []
      lines = secrets.filter_map do |secret|
        name, value = secret["name"], secret["value"].to_s
        unless valid_name?(name)
          warnings << "skipped secret #{name.inspect}: not a valid variable name. " \
                      "Rename it to use only letters, numbers and _ (not starting with a number), or use --format=json."
          next
        end
        if format == "dotenv" && !portable_in_dotenv?(value)
          warnings << "secret #{name.inspect} contains ' together with \", \\ or $. Ruby dotenv and " \
                      "Docker Compose read it correctly; Node's dotenv keeps the backslash escapes."
        end
        line(name, value, format)
      end
      [lines.join, warnings]
    end

    def line(name, value, format)
      case format
      when "env"    then "#{name}=#{shell_quote(value)}\n"
      when "shell"  then "export #{name}=#{shell_quote(value)}\n"
      when "dotenv" then "#{name}=#{dotenv_quote(value)}\n"
      when "github" then github_entry(name, value)
      else raise ArgumentError, "unknown format: #{format}"
      end
    end

    # POSIX single quotes: nothing inside is special except the closing
    # quote itself, which is written as '\'' (close, escaped quote, reopen).
    def shell_quote(value)
      "'#{value.gsub("'", %q('\\\\''))}'"
    end

    # Single-quoted values, line breaks included, are literal in every
    # common dotenv parser (Ruby dotenv, Node dotenv, Docker Compose), so use
    # them whenever the value has no ' of its own. Double quotes are next:
    # also literal as long as there's no ", \ or $ to interpret. Only a value
    # with both needs escapes, and parsers disagree on those: Ruby dotenv and
    # Compose unescape \" \\ \$ (and Ruby runs $(...) if $ isn't escaped),
    # while Node's dotenv leaves the backslashes in.
    def dotenv_quote(value)
      return "'#{value}'" unless value.include?("'")
      return "\"#{value}\"" unless value.match?(/["\\$]/)

      "\"#{value.gsub(/["\\$]/) { |char| "\\#{char}" }}\""
    end

    def portable_in_dotenv?(value)
      !(value.include?("'") && value.match?(/["\\$]/))
    end

    # GitHub's multiline syntax for $GITHUB_ENV. A random delimiter means a
    # value can't close the block early and smuggle in another variable
    # (e.g. NODE_OPTIONS) for later workflow steps.
    def github_entry(name, value)
      delimiter = "VAULTEZ_EOF_#{SecureRandom.hex(16)}"
      delimiter = "VAULTEZ_EOF_#{SecureRandom.hex(16)}" while value.include?(delimiter)
      "#{name}<<#{delimiter}\n#{value}\n#{delimiter}\n"
    end
  end
end
