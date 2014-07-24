require 'json'
require 'yaml'

class SongsController < ApplicationController
  protect_from_forgery except: [:add, :skip]

  def add
    info = write_file params
    save_info info
  end

  def add_url
    render :json => {:status => 'ng'} and return if params[:url].nil?

    info = download_file(params)
    save_info info

    render :json => {:status => 'ok'}
  end

  def skip
    Redis.current.publish 'skip', :skip
    render text: 'ok'
  end

  def index
    case params[:format]
    when "json"
      begin
        songs = Redis.current.lrange("playlist",0,10).map {|song_id| Redis.current.get(song_id)}
      rescue Redis::CannotConnectError => e
        render :json => {status: 'ok'}
        return
      end

      current_song = songs[0..0].map{|song| eval(song)}
      next_songs = (songs[1..-1] || []).map{|song| eval(song)}

      render :json => {current: current_song.first, next: next_songs}

    when "html"
      respond_to do |format|
        format.html
      end
    else
      render :text => ""
    end
  end

  private
  def dir
    File.expand_path("public/music", Rails.root).tap(&FileUtils.method(:mkdir_p))
  end

  def account
    YAML::load(File.read("#{Rails.root}/config/account.yml"))
  end

  def write_file(params)
    filename = Time.now.strftime("%Y%m%d%H%M%S%L.m4a")
    path = File.expand_path(filename, dir)
    IO.binwrite(path, params[:file].read)

    IO.binwrite(File.expand_path("#{filename}.artwork.jpg", dir), params[:artwork].read)

    url =  "http://#{request.host}:#{request.port}/music/#{filename}"

    info = ({path: path, url: url})
    params.slice(:title, :artist).each{|k,v| info[k] = CGI.unescape(v)}
    info['artwork'] = "#{url}.artwork.jpg"
    info
  end

  def download_file(params)
    url = params[:url]
    json = JSON::parse(`youtube-dl --dump-json "#{url}"`)

    time = Time.now.strftime("%Y%m%d%H%M%S%L")
    video_filename = "#{time}.#{json['ext']}"

    if account[json["extractor"]]
      username = account[json["extractor"]]["username"]
      password = account[json["extractor"]]["password"]
      puts `youtube-dl -u #{username} -p #{password} -o "public/music/#{video_filename}" "#{url}"`
    else
      puts `youtube-dl -o "public/music/#{video_filename}" "#{url}"`
    end

    title = json["title"]
    artist = json["uploader"]
    path = File.expand_path(video_filename, dir)
    url =  "http://#{request.host}:#{request.port}/music/#{video_filename}"
    artwork_url = json["thumbnail"]

    {title: title, artist: artist, path: path, url: url, artwork: artwork_url}
  end

  def save_info(info)
    count = Redis.current.incr "song-id"
    id = "song:#{count}"
    Rails.logger.debug "Add '#{id}' with #{info.inspect}"
    Redis.current.set id, info
    Redis.current.rpush "playlist", id
  end
end
