# frozen_string_literal: true

require "json"
require "fileutils"

module WaBot
  class UserStore
    def initialize(base_dir: File.expand_path("~/.wabot"))
      @storage_dir = File.join(base_dir, "storage")
      FileUtils.mkdir_p(@storage_dir)
      @users_file = File.join(@storage_dir, "users.json")
      initialize_file
    end

    def register(username)
      raise "Username is required" if username.to_s.strip.empty?

      users = read_users
      raise "User already exists" if users.any? { |u| u["username"] == username }

      users << { "username" => username }
      write_users(users)
      true
    end

    def authenticate(username)
      users = read_users
      users.any? { |u| u["username"] == username }
    end

    def users
      read_users
    end

    private

    def initialize_file
      unless File.exist?(@users_file)
        File.write(@users_file, JSON.pretty_generate({ users: [] }))
      end
    end

    def read_users
      data = JSON.parse(File.read(@users_file))
      data["users"] || []
    rescue
      []
    end

    def write_users(users)
      File.write(@users_file, JSON.pretty_generate({ users: users }))
    end
  end
end
