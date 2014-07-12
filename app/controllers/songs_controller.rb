class SongsController < ApplicationController
  protect_from_forgery except: :add
  def add
    info = write_file request.body
    save_info info
  end

  def index
  end

  private
  def dir
    File.expand_path("public/music", Rails.root).tap(&FileUtils.method(:mkdir_p))
  end

  def write_file(io)
    filename = Time.now.strftime("%Y%m%d%H%M%S%L.m4a")
    path = File.expand_path(filename, dir)
    IO.binwrite(path, io.read)

    url =  "http://#{request.host}:#{request.port}/music/#{filename}"

    { path: path, url: url }
  end

  def save_info(info)
    count = Redis.current.incr "song-id"
    id = "song:#{count}"
    Rails.logger.debug "Add '#{id}' with #{info.inspect}"
    Redis.current.set id, info
    Redis.current.rpush "playlist", id
  end
end
