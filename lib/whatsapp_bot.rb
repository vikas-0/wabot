# frozen_string_literal: true

require_relative "whatsapp_bot/version"
require_relative "whatsapp_bot/bot"

module WhatsAppBot
  # Open a WhatsApp Web browser session for a given username and yield the bot.
  # Ensures the browser is closed after the block even if an error occurs.
  #
  # Example:
  #   WhatsAppBot.session(username: "alice") do |bot|
  #     bot.send_message(phone_number: "+14155552671", message: "Hello")
  #     bot.send_message(phone_number: "+14155552672", message: "Hi again")
  #   end
  #
  # Options:
  # - headless: run Chrome headless (default: false)
  # - timeout: seconds to wait for WhatsApp Web chat list (default: 180)
  # - base_dir: base directory for profiles/ and storage/ (default: project root)
  # - require_login: if true, waits for chat list; if false, skips the check (default: true)
  def self.session(username:, headless: false, timeout: 180, base_dir: File.expand_path("~/.whatsapp_bot"), require_login: true)
    bot = Bot.new(username: username, headless: headless, base_dir: base_dir)
    begin
      bot.start
      if require_login
        ok = bot.ensure_logged_in(timeout: timeout)
        unless ok
          raise "Not logged into WhatsApp Web for user '#{username}'. Run wa_login or open a non-headless session to scan QR."
        end
      end
      yield bot
    ensure
      bot.close
    end
  end

  # Convenience: open a session, send one message, and close.
  def self.send_message(username:, to:, message:, headless: false, timeout: 180, base_dir: File.expand_path("~/.whatsapp_bot"))
    session(username: username, headless: headless, timeout: timeout, base_dir: base_dir) do |bot|
      bot.send_message(phone_number: to, message: message)
    end
  end

  # Open a visible Chrome window and wait for QR login (up to timeout seconds).
  # Returns true if chat list detected, false otherwise.
  def self.login(username:, timeout: 180, base_dir: File.expand_path("~/.whatsapp_bot"), headless: false)
    bot = Bot.new(username: username, headless: headless, base_dir: base_dir)
    begin
      bot.start
      bot.ensure_logged_in(timeout: timeout)
    ensure
      bot.close
    end
  end
end
