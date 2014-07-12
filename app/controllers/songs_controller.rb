class SongsController < ApplicationController
  protect_from_forgery except: :add

  def add
    info = write_file params
    save_info info
  end

  def skip
    Redis.current.publish 'skip', :skip
    render text: 'ok'
  end

  def index
    case params[:format]
    when "json"
      begin
        songs = Redis.current.keys("song:*").sort.map {|song_id| Redis.current.get(song_id)}
      rescue Redis::CannotConnectError => e
        render :json => {status: 'ok'}
        return
      end

      current_song = songs[0..0].map{|song| eval(song)}
      next_songs = songs[1..-1].map{|song| eval(song)}

      render :json => {current: current_song, next: next_songs}

    when "html"
      render :text => ""
    else
      render :text => ""
    end
  end

  private
  def dir
    File.expand_path("public/music", Rails.root).tap(&FileUtils.method(:mkdir_p))
  end

  def write_file(params)
    filename = Time.now.strftime("%Y%m%d%H%M%S%L.m4a")
    path = File.expand_path(filename, dir)
    IO.binwrite(path, params[:file].read)

    url =  "http://#{request.host}:#{request.port}/music/#{filename}"

    { path: path, url: url, title: params[:title] }
  end

  def save_info(info)
    count = Redis.current.incr "song-id"
    id = "song:#{count}"
    Rails.logger.debug "Add '#{id}' with #{info.inspect}"
    Redis.current.set id, info
    Redis.current.rpush "playlist", id
  end
end
