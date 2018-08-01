require "./demetrius/*"
require "tourmaline"
require "ydl"
require "http"


alias TGBot = Tourmaline::Bot

bot = TGBot::Client.new(ENV["TELEGRAM_API_KEY"])
puts("Bot starting")
videos = [] of Ydl::Video

bot.command(["help"]) do |message|
  text = "gets help!"
  bot.send_message(message.chat.id, text)
end

bot.command("ydl") do |msg, args|
  if args.size != 1
    text = "You need to send one, and only *one*, url!"
    bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: :markdown)
    next
  end
  
  text = "Let me try and fetch that!"
  bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: :markdown)
  bot.send_chat_action(msg.chat.id, action: :typing)

  begin
    print(args[0])
    video = Ydl::Video.new(args[0])
  rescue ex
    text = "That wasn't a valid url"
    puts(ex.message)
    bot.send_message(msg.chat.id, text, parse_mode: :markdown)
    next
  end

  videos << video

  audio_buttons = video.audio_formats.map do |f|
    TGBot::InlineKeyboardButton.new(f.name, callback_data: f.id)
  end

  video_buttons = video.full_formats.map do |f|
    TGBot::InlineKeyboardButton.new(f.name, callback_data: f.id)
  end

  inline_buttons = [] of Array(TGBot::InlineKeyboardButton)

  (audio_buttons + video_buttons).each_slice(2) do |s|
    inline_buttons << s
  end

  inline_buttons << [TGBot::InlineKeyboardButton.new("Cancel", callback_data: "cancel")]
  inline_kb = TGBot::InlineKeyboardMarkup.new(inline_buttons)

  text = %<Is this what you want?\n\n[#{video.title}](#{video.url})>
  bot.send_message(msg.chat.id, text, parse_mode: :markdown, 
                  reply_markup: inline_kb)
end

bot.on(TGBot::UpdateAction::Text) do |update|
  text = update.message.not_nil!.text.not_nil!
  puts "TEXT: #{text}"
end

bot.on(TGBot::UpdateAction::CallbackQuery) do |update|
  cb = update.callback_query.not_nil!
  msg = cb.message.not_nil!
  puts "CB: #{cb.data}"

  if cb.data == "cancel"
    bot.delete_message(msg.chat.id, msg.message_id)
    next
  end

  temp_msg = bot.send_message(msg.chat.id, "Ok. Downloading right now...")
  puts(temp_msg.to_json)
  bot.send_chat_action(msg.chat.id, action: :record_video)
  path = videos.last.not_nil!.download(cb.data.not_nil!)
  puts "Video downloaded to #{path}" 
  temp_msg = bot.edit_message_text(temp_msg.chat.id, "Done. I'm uploading to you", temp_msg.message_id)
  bot.send_chat_action(msg.chat.id, action: :upload_video)
  video_file = File.open(path)
  bot.send_video(msg.chat.id, video_file)
end

puts("Bot listening...")
bot.poll
