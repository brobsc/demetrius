require "./demetrius/*"
require "http"
require "tourmaline"

alias TGBot = Tourmaline::Bot
bot = TGBot::Client.new(ENV["TELEGRAM_API_KEY"])


spawn do
  Demetrius.wait_server bot
end

Demetrius.telegram_start bot
