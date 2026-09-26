require "test_helper"
require "open3"
require "tmpdir"

class FetchTest < Minitest::Test
  include CliHelpers

  PROJECT = ["fetch", "--company=Test Company", "--project=Test Project"].freeze

  def tricky_values(marker)
    {
      "SPACE"     => "abc def",
      "SINGLE"    => "it's",
      "DOUBLE"    => 'say "hi"',
      "HASH"      => "abc #123",
      "SEMI"      => "a; touch #{marker}",
      "SUBST"     => "$(touch #{marker})",
      "BACKTICK"  => "`touch #{marker}`",
      "DOLLAR"    => "$HOME and ${PATH}",
      "BACKSLASH" => 'C:\path\n',
      "NEWLINE"   => "line1\nline2",
      "EMPTY"     => ""
    }
  end

  # Feeds the CLI's stdout to bash through `snippet` and reads the resulting
  # variables back out, NUL-separated so newlines survive.
  def through_bash(stdout, names, snippet)
    script = <<~SH
      #{snippet}
      for name in #{names.join(" ")}; do printf '%s\\0' "${!name}"; done
    SH
    out, status = Open3.capture2("bash", "-c", script, stdin_data: stdout)
    assert status.success?, "bash failed"
    names.zip(out.split("\0", -1))
  end

  %w[eval source].each do |mode|
    define_method("test_default_output_round_trips_through_#{mode}_without_running_anything") do
      Dir.mktmpdir do |dir|
        marker = File.join(dir, "pwned")
        values = tricky_values(marker)
        out, err, status = run_cli(*PROJECT, secrets: values.map { |k, v| secret(k, v) })

        assert_equal 0, status
        assert_empty err
        snippet = mode == "eval" ? 'eval "$(cat)"' : "set -a; source /dev/stdin; set +a"
        through_bash(out, values.keys, snippet).each do |name, value|
          assert_equal values.fetch(name), value, "wrong value for #{name}"
        end
        refute File.exist?(marker), "a secret value ran a command"
      end
    end
  end

  def test_shell_format_exports
    out, = run_cli(*PROJECT, "--format=shell", secrets: [secret("A", "x y")])
    assert_equal "export A='x y'\n", out
    values = through_bash(out, ["A"], 'eval "$(cat)"; bash -c \'test "$A" = "x y"\' || exit 1')
    assert_equal [["A", "x y"]], values
  end

  def test_dotenv_format
    out, err, = run_cli(*PROJECT, "--format=dotenv", secrets: [
      secret("PLAIN", "abc #123 $HOME $(x) \"q\" \\"),
      secret("MULTI", "line1\nline2"),
      secret("APOS", "it's\nfine"),
      secret("MIXED", "it's $5 \"q\" \\")
    ])
    assert_equal <<~ENV, out
      PLAIN='abc #123 $HOME $(x) "q" \\'
      MULTI='line1
      line2'
      APOS="it's
      fine"
      MIXED="it's \\$5 \\"q\\" \\\\"
    ENV
    assert_equal 1, err.lines.size
    assert_includes err, %(secret "MIXED" contains ')
  end

  def test_github_format_uses_random_heredoc_delimiters
    out, = run_cli(*PROJECT, "--format=github", secrets: [
      secret("MULTI", "line1\nNODE_OPTIONS=--require=/tmp/evil.js")
    ])
    lines = out.lines(chomp: true)
    assert_match(/\AMULTI<<(VAULTEZ_EOF_\h{32})\z/, lines[0])
    delimiter = lines[0].split("<<").last
    assert_equal ["line1", "NODE_OPTIONS=--require=/tmp/evil.js", delimiter], lines[1..]
  end

  def test_invalid_names_are_skipped_with_a_warning
    out, err, status = run_cli(*PROJECT, secrets: [
      secret("Test Secret", "x"), secret("1ABC", "y"), secret("GOOD", "z")
    ])
    assert_equal 0, status
    assert_equal "GOOD='z'\n", out
    assert_includes err, %(skipped secret "Test Secret")
    assert_includes err, %(skipped secret "1ABC")
  end

  def test_json_keeps_all_names
    secrets = [secret("Test Secret", "x"), secret("GOOD", "z")]
    [["--json"], ["--format=json"]].each do |flags|
      out, err, status = run_cli(*PROJECT, *flags, secrets: secrets)
      assert_equal 0, status
      assert_empty err
      assert_equal secrets, JSON.parse(out)
    end
  end

  def test_json_conflicting_with_another_format_fails
    out, err, status = run_cli(*PROJECT, "--json", "--format=env", secrets: [secret("A", "b")])
    assert_equal 1, status
    assert_empty out
    assert_includes err, "--json can't be combined"
  end

  def test_errors_go_to_stderr_in_every_mode
    [[], ["--json"], ["--format=dotenv"]].each do |flags|
      out, err, status = run_cli("fetch", "--company=Test Company", "--project=nope", *flags)
      assert_equal 1, status
      assert_empty out
      assert_includes err, %(Error: project "nope" not found in Test Company.)
    end
  end

  def test_no_secrets_prints_nothing_to_stdout
    out, err, status = run_cli(*PROJECT)
    assert_equal 0, status
    assert_empty out
    assert_includes err, "No secrets found in Test Project."

    out, err, status = run_cli("fetch", token_mode: true)
    assert_equal 0, status
    assert_empty out
    assert_includes err, "No secrets found."
  end

  def test_project_token_mode_uses_the_same_formatting
    out, _, status = run_cli("fetch", token_mode: true, secrets: [secret("A", "$(x)")])
    assert_equal 0, status
    assert_equal "A='$(x)'\n", out
  end

  def test_single_secret_prints_the_raw_value
    out, err, status = run_cli(*PROJECT, "--secret=Test Secret", secrets: [secret("Test Secret", "a b'c")])
    assert_equal 0, status
    assert_empty err
    assert_equal "a b'c", out
  end

  def test_missing_single_secret_fails_on_stderr
    out, err, status = run_cli(*PROJECT, "--secret=NOPE")
    assert_equal 1, status
    assert_empty out
    assert_includes err, %(secret "NOPE" not found)
  end

  def test_usage_errors_exit_non_zero
    out, err, status = run_cli(*PROJECT, "--format=yaml")
    assert_equal 1, status
    assert_empty out
    assert_includes err, "Expected '--format' to be one of"
  end

  def test_not_enough_options_fails_on_stderr
    out, err, status = run_cli("fetch")
    assert_equal 1, status
    assert_empty out
    assert_includes err, "not enough options"
  end
end
