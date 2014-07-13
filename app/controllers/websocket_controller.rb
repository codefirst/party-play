class WebsocketController <  WebsocketRails::BaseController
  include SongsConcerns

  def song_changed
    broadcast_message :song_added, get_songs
  end

end
