class SongsController < ApplicationController
  protect_from_forgery except: :add
  def add
    path = write_file request.body
    save_info path
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
    path
  end

  def save_info(path)
    count = Redis.current.incr "song-id"
    id = "song:#{count}"
    Rails.logger.debug "Add '#{id}' with { path: #{path.inspect} }"
    Redis.current.set id, { path: path }
    Redis.current.rpush "playlist", id
  end
end
