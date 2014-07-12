class SongsController < ApplicationController
  protect_from_forgery except: :add
  def add
    filename = Time.now.strftime("%Y%m%d%H%M%S%L.m4a")
    path = File.expand_path(filename, dir)
    IO.binwrite(path, request.body.read)
  end

  def index
  end

  private
  def dir
    File.expand_path("public/music", Rails.root).tap(&FileUtils.method(:mkdir_p))
  end
end
