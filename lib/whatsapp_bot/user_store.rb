# frozen_string_literal: true

require "json"
require "bcrypt"
require "fileutils"

module WhatsAppBot
  class UserStore
    def initialize(base_dir: File.expand_path("../../..", __dir__))
      @storage_dir = File.join(base_dir, "storage")
      FileUtils.mkdir_p(@storage_dir)
      @users_file = File.join(@storage_dir, "users.json")
      initialize_file
    end

    def register(username, password)
      raise "Username is required" if username.to_s.strip.empty?
      raise "Password is required" if password.to_s.strip.empty?

      users = read_users
      raise "User already exists" if users.any? { |u| u["username"] == username }

      password_hash = BCrypt::Password.create(password)
      users << { "username" => username, "password_hash" => password_hash }
      write_users(users)
      true
    end

    def authenticate(username, password)
      users = read_users
      user = users.find { |u| u["username"] == username }
      return false unless user

      begin
        BCrypt::Password.new(user["password_hash"]) == password
      rescue
        false
      end
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
