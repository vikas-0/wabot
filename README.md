# WaBot (Ruby)

A simple personal WhatsApp Web bot using Ruby, Selenium, and WhatsApp Web. No WhatsApp Business API required.

Features:
- Register/login local users (credentials stored locally, password hashed with bcrypt)
- Persist WhatsApp Web session per user via Chrome profile directory
- CLI to login to WhatsApp Web (QR) and send messages

## Prerequisites
- Ruby 3.0+
- Google Chrome installed

## Setup
```
cd wabot
bundle install
```

Note: This project uses Selenium Manager (built into selenium-webdriver >= 4.11) to automatically manage the browser driver. You do NOT need the `webdrivers` gem.

## Usage
1) Register a local user:
```
ruby bin/wabot register -u alice -p secret123
```

2) Login as that local user:
```
ruby bin/wabot login -u alice -p secret123
```

3) Log in to WhatsApp Web (scan QR once). A Chrome window will open:
```
ruby bin/wabot wa_login
```
Wait until you see your chat list.

4) Send a message (reuses the saved WhatsApp Web session for the current user):
```
ruby bin/wabot send -t "+1234567890" -m "Hello from WaBot!"
```

Notes:
- Phone number must be in international format including country code, e.g., +14155552671
- Each local user gets a separate Chrome profile under `profiles/<username>` to persist WhatsApp login
 - Selenium Manager will handle downloading a compatible chromedriver automatically

## Security
- Local user passwords are hashed with bcrypt and stored in `storage/users.json`
- The current CLI login session is stored in `storage/session.json`
- Your WhatsApp Web cookies/tokens live inside `profiles/<username>`; keep this folder private

## Troubleshooting
- If WhatsApp Web UI changes and selectors break, update selectors in `lib/wabot/bot.rb`
- If Chrome fails to start in headless on macOS, try without `--headless` (default)
- Clear a user's WhatsApp session by deleting `profiles/<username>` (you'll need to scan QR again)

## Gem usage (Ruby API)

You can use this as a library in your own Ruby code. Build and install the gem locally:

```
cd wabot
gem build wabot.gemspec
gem install ./wabot-0.1.0.gem
```

Then, in your Ruby app:

```ruby
require "wabot"

# First-time only: open a visible window and log in (scan QR)
WaBot.login(username: "alice", headless: false)

# Later: open a session and send multiple messages inside a block
WaBot.session(username: "alice", headless: true) do |bot|
  bot.send_message(phone_number: "+14155552671", message: "Hello from WaBot")
  bot.send_message(phone_number: "+14155552672", message: "Second message")
end
```

Using with Bundler (Gemfile):

```
gem "wabot", "~> 0.1.0"
```

Then in code:

```ruby
require "wabot"
```

CLI when installed via gem:

```
wabot login -u alice
wabot send -t "+1234567890" -m "Hello from WaBot" --headless
```

Notes:
- Library defaults to storing Chrome profiles under `~/.wabot/profiles/<username>` so your session persists across uses.
- If you prefer a visible browser for debugging, set `headless: false` in `WaBot.session(...)`.
