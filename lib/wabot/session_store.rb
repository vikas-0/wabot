# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

module WaBot
  class SessionStore
    def initialize(base_dir: File.expand_path("~/.wabot"))
      @storage_dir = File.join(base_dir, "storage")
      FileUtils.mkdir_p(@storage_dir)
      @session_file = File.join(@storage_dir, "session.json")
      initialize_file
    end

    def login(username)
      data = { "current_user" => username, "logged_in_at" => Time.now.utc.iso8601 }
      File.write(@session_file, JSON.pretty_generate(data))
      true
    end

    def current_user
      data = JSON.parse(File.read(@session_file))
      data["current_user"]
    rescue
      nil
    end

    def logged_in?
      !current_user.nil?
    end

    def logout
      File.write(@session_file, JSON.pretty_generate({ "current_user" => nil }))
      true
    end

    private

    def initialize_file
      unless File.exist?(@session_file)
        File.write(@session_file, JSON.pretty_generate({ "current_user" => nil }))
      end
    end
  end
end
