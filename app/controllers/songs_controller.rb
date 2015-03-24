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

    info = download_file_asynchronously(params)
    render :json => {status: 'ok', info: info}
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

  def download_file_asynchronously(params)
    url = params[:url]
    json = JSON::parse(`youtube-dl --dump-json "#{url}"`)

    Process::fork do
      download_command = "youtube-dl -x"
      if account[json["extractor"]]
        username = account[json["extractor"]]["username"]
        password = account[json["extractor"]]["password"]
        download_command = "#{download_command} -u #{username} -p #{password}"
      end

      time = Time.now.strftime("%Y%m%d%H%M%S%L")
      video_filename = "#{time}.#{json['ext']}"

      puts `#{download_command} -o "#{dir}/#{video_filename}" "#{url}"`
      audio_filename = nil
      ["m4a", "mp3", "mp4"].each do |ext|
        filename = "#{time}.#{ext}"
        audio_filename = filename if File.exists?("#{dir}/#{filename}")
      end

      title = json["title"]
      artist = json["uploader"]
      path = File.expand_path(audio_filename, dir)
      url =  "http://#{request.host}:#{request.port}/music/#{audio_filename}"
      artwork_url = json["thumbnail"]

      save_info(title: title, artist: artist, path: path, url: url, artwork: artwork_url)
    end

    json
  end

  def save_info(info)
    count = Redis.current.incr "song-id"
    id = "song:#{count}"
    Rails.logger.debug "Add '#{id}' with #{info.inspect}"
    Redis.current.set id, info
    Redis.current.rpush "playlist", id
  end
end
