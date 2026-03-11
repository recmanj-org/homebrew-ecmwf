# frozen_string_literal: true

require "download_strategy"

class GitHubPrivateDownloadStrategy < GitHubGitDownloadStrategy
  GITHUB_REPO_URL_REGEX = %r{
    \Ahttps://github\.com/
    (?<owner>[^/]+)/
    (?<repo>[^/]+)\.git
    \z
  }x

  def initialize(url, name, version, token_env:, **meta)
    match = url.match(GITHUB_REPO_URL_REGEX)
    raise "Unsupported GitHub repository URL: #{url}" unless match

    @token = ENV[token_env].to_s
    @token_env = token_env
    @original_url = url
    super(url, name, version, **meta)
    @url = "https://x-access-token:#{@token}@github.com/#{match[:owner]}/#{match[:repo]}.git" unless @token.empty?
  end

  def fetch(timeout: nil)
    raise "#{@token_env} is required to download #{@original_url}" if @token.empty?

    # macOS git defaults to the osxkeychain credential helper, which can prompt
    # for keychain access (or block on a GUI dialog) in CI environments. Disable
    # all prompting so git fails fast rather than hanging forever.
    ENV["GIT_TERMINAL_PROMPT"] = "0"
    ENV["GIT_CONFIG_COUNT"] = "1"
    ENV["GIT_CONFIG_KEY_0"] = "credential.helper"
    ENV["GIT_CONFIG_VALUE_0"] = ""
    super
  end
end
