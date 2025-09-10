# frozen_string_literal: true

require "selenium-webdriver"
require "fileutils"
require "uri"

module WhatsAppBot
  class Bot
    BASE_URL = "https://web.whatsapp.com"

    def initialize(username:, base_dir: File.expand_path("~/.whatsapp_bot"), headless: false)
      @username = username
      @base_dir = base_dir
      @profiles_dir = File.join(@base_dir, "profiles")
      FileUtils.mkdir_p(@profiles_dir)
      @user_profile_dir = File.join(@profiles_dir, username)
      FileUtils.mkdir_p(@user_profile_dir)
      @driver = nil
      @headless = headless
    end

    def start
      opts = Selenium::WebDriver::Chrome::Options.new
      opts.add_argument("--user-data-dir=#{@user_profile_dir}")
      opts.add_argument("--no-sandbox")
      opts.add_argument("--disable-dev-shm-usage")
      opts.add_argument("--window-size=1280,900")
      opts.add_argument("--headless=new") if @headless

      @driver = Selenium::WebDriver.for(:chrome, options: opts)
      @driver.navigate.to(BASE_URL)
    end

    def ensure_logged_in(timeout: 90)
      wait = Selenium::WebDriver::Wait.new(timeout: timeout)
      begin
        wait.until do
          begin
            @driver.find_element(css: "div[data-testid='chat-list']")
          rescue Selenium::WebDriver::Error::NoSuchElementError
            begin
              @driver.find_element(css: "div[aria-label='Chat list']")
            rescue Selenium::WebDriver::Error::NoSuchElementError
              nil
            end
          end
        end
        true
      rescue Selenium::WebDriver::Error::TimeoutError
        false
      end
    end

    def send_message(phone_number:, message:)
      ensure_driver!
      # WhatsApp expects digits only (no '+', spaces, hyphens)
      digits_phone = phone_number.to_s.gsub(/\D/, "")
      encoded_text = URI.encode_www_form_component(message)
      chat_url = "#{BASE_URL}/send?phone=#{digits_phone}&text=#{encoded_text}"
      @driver.navigate.to(chat_url)

      wait = Selenium::WebDriver::Wait.new(timeout: 60)
      begin
        # Wait until the message box (preferred) or a send button is visible
        wait.until { !!(find_message_box || find_send_button) }

        # Always attempt to type the message explicitly to avoid relying on URL prefill
        box = find_message_box
        if box
          box.click
          sleep 0.15
          # Select-all + delete to clear any previous text
          modifier = (RUBY_PLATFORM =~ /darwin/i ? :command : :control)
          box.send_keys([modifier, 'a'])
          box.send_keys(:backspace)
          sleep 0.05
          box.send_keys(message)
          sleep 0.1
        end

        # Prefer clicking the send button if present
        if (btn = find_send_button)
          begin
            @driver.execute_script("arguments[0].click();", btn)
          rescue
            btn.click
          end
        else
          # If no button, try Enter/Return inside the composer
          if box
            box.send_keys(:enter)
            sleep 0.2
            unless composer_text.to_s.strip.empty?
              box.send_keys(:return)
            end
          else
            # As a last resort, press Enter/Return on body
            body = @driver.find_element(tag_name: "body")
            body.send_keys(:enter)
            sleep 0.2
            # Try :return if still not sent
            if composer_text && !composer_text.to_s.strip.empty?
              body.send_keys(:return)
            end
          end
        end

        # Primary verification: new outgoing bubble with the same text appears
        begin
          Selenium::WebDriver::Wait.new(timeout: 8).until do
            message_sent?(message)
          end
          return true
        rescue Selenium::WebDriver::Error::TimeoutError
          # Secondary verification: composer cleared
          begin
            Selenium::WebDriver::Wait.new(timeout: 3).until do
              current = composer_text
              current.nil? || current.strip.empty?
            end
            return true
          rescue Selenium::WebDriver::Error::TimeoutError
            return false
          end
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        # Timed out waiting; try body Enter
        body = @driver.find_element(tag_name: "body")
        body.send_keys(:enter)
        true
      rescue => e
        warn "Failed to send message: #{e.message}"
        false
      end
    end

    # Convenience alias
    def send_to(phone_number, text)
      send_message(phone_number: phone_number, message: text)
    end

    def close
      @driver&.quit
      @driver = nil
    end

    private

    def ensure_driver!
      raise "Driver not started. Call start first." unless @driver
    end

    def find_message_box
      # Try several known selectors WhatsApp uses for the main composer textbox
      candidates = [
        "div[data-testid='conversation-compose-box-input']",
        "div[contenteditable='true'][data-tab='10']",
        "div[contenteditable='true'][data-tab='6']",
        "div[aria-label='Type a message']",
        "div[title='Type a message']"
      ]
      candidates.each do |css|
        begin
          el = @driver.find_element(css: css)
          return el if el.displayed?
        rescue Selenium::WebDriver::Error::NoSuchElementError
        end
      end
      nil
    end

    def find_send_button
      # Try multiple variants for the send button
      css_candidates = [
        "button[data-testid='compose-btn-send']",
        "button[aria-label='Send']",
        "button[aria-label='Send message']"
      ]
      css_candidates.each do |css|
        begin
          el = @driver.find_element(css: css)
          return el if el.displayed?
        rescue Selenium::WebDriver::Error::NoSuchElementError
        end
      end
      # Older UI: span icon
      begin
        span = @driver.find_element(css: "span[data-icon='send']")
        return span.find_element(xpath: "./ancestor::button")
      rescue Selenium::WebDriver::Error::NoSuchElementError
      end
      nil
    end

    def composer_text
      el = find_message_box
      return nil unless el
      el.text
    rescue
      nil
    end

    def message_sent?(text)
      begin
        # Look for outgoing message bubbles containing our text
        nodes = @driver.find_elements(css: "div.message-out span.selectable-text, div.message-out span[dir='auto']")
        nodes.any? { |n| n.text.to_s.strip == text.to_s.strip }
      rescue
        false
      end
    end
  end
end
