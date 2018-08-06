require "json"

module Demetrius
  def self.wait_server(bot)
    port = ENV.fetch("DEMETRIUS_PORT", "8090").to_i
    server = HTTP::Server.new([
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
    ]) do |ctx|
      case ctx.request.method
      when "POST"
        ctx.response.content_type = "application/json"
        resp = {} of String => String

        if (body = ctx.request.body) &&
           (ip = JSON.parse(body)["ban"]?)
          resp["success"] = "Banning #{ip}"
          bot.send_message(ENV.fetch("TELEGRAM_BOT_ADM"),
                           %<🚫Banned: #{ip}\nhttp://ip-api.com/#{ip}>)
        else
          resp["error"] = "Invalid IP"
        end

        ctx.response.print resp.to_json
      else
        ctx.response.print File.read(__DIR__ + "/index.html")
        ctx.response.content_type = "text/html"
      end
    end

    addr = server.bind_tcp port
    puts "Listening at http://#{addr}"

    server.listen
  end
end
