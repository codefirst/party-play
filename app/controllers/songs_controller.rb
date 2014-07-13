class SongsController < ApplicationController
  include SongsConcerns

  protect_from_forgery except: [:add, :skip]

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
      songs = get_songs
      if songs
        render :json => songs
      else
        render :json => {status: 'ok'}
      end
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

  def save_info(info)
    count = Redis.current.incr "song-id"
    id = "song:#{count}"
    Rails.logger.debug "Add '#{id}' with #{info.inspect}"
    Redis.current.set id, info
    Redis.current.rpush "playlist", id
  end
end
