# frozen_string_literal: true

require "thor"
require "colorize"
require_relative "version"
require_relative "user_store"
require_relative "session_store"
require_relative "bot"

module WaBot
  class CLI < Thor
    desc "register", "Register a new local user"
    method_option :username, aliases: "-u", type: :string, required: true, desc: "Username"
    def register
      store = UserStore.new
      begin
        store.register(options[:username])
        puts "User registered: #{options[:username]}".green
      rescue => e
        puts "Error: #{e.message}".red
        exit 1
      end
    end

    desc "login", "Login as a local user"
    method_option :username, aliases: "-u", type: :string, required: true
    def login
      store = UserStore.new
      unless store.authenticate(options[:username])
        puts "User not found. Please register first.".red
        exit 1
      end
      session = SessionStore.new
      session.login(options[:username])
      puts "Logged in as #{options[:username]}".green
    end

    desc "logout", "Logout current local user"
    def logout
      session = SessionStore.new
      if session.logged_in?
        user = session.current_user
        session.logout
        puts "Logged out: #{user}".yellow
      else
        puts "No user is currently logged in".yellow
      end
    end

    desc "wa_login", "Open WhatsApp Web to log in (QR) for the current user"
    method_option :headless, type: :boolean, default: false, desc: "Run Chrome in headless mode"
    def wa_login
      session = SessionStore.new
      unless session.logged_in?
        puts "Please login as a local user first (cli login)".red
        exit 1
      end

      bot = Bot.new(username: session.current_user, headless: options[:headless])
      begin
        bot.start
        puts "A Chrome window has opened. Scan the QR code with your phone to login to WhatsApp Web.".cyan
        if bot.ensure_logged_in(timeout: 180)
          puts "WhatsApp Web login successful!".green
        else
          puts "Timed out waiting for WhatsApp Web login.".red
        end
      ensure
        bot.close
      end
    end

    desc "send", "Send a WhatsApp message"
    method_option :to, aliases: "-t", type: :string, required: true, desc: "Phone number in international format, e.g. +1234567890"
    method_option :message, aliases: "-m", type: :string, required: true, desc: "Message text"
    method_option :headless, type: :boolean, default: false
    method_option :keep_open, type: :boolean, default: false, desc: "Keep the browser open after sending (debug)"
    def send
      session = SessionStore.new
      unless session.logged_in?
        puts "Please login as a local user first (cli login)".red
        exit 1
      end

      bot = Bot.new(username: session.current_user, headless: options[:headless])
      begin
        bot.start
        unless bot.ensure_logged_in(timeout: 180)
          puts "Not logged into WhatsApp Web. Please run `wa_login` to scan the QR code first.".red
          exit 1
        end
        if bot.send_message(phone_number: options[:to], message: options[:message])
          puts "Message sent to #{options[:to]}".green
        else
          puts "Failed to send message".red
          exit 1 unless options[:keep_open]
        end
        if options[:keep_open]
          puts "Keeping browser open. Press Enter to quit...".yellow
          STDIN.gets
        end
      ensure
        bot.close unless options[:keep_open]
      end
    end

    desc "version", "Print version"
    def version
      puts WaBot::VERSION
    end
  end
end
