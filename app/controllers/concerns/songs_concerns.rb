module SongsConcerns
  extend ActiveSupport::Concern
  def get_songs
    begin
      songs = Redis.current.lrange("playlist", 0, 10).map {|song_id| Redis.current.get(song_id)}
    rescue Redis::CannotConnectError => e
      return nil
    end

    current_song = songs[0..0].map{|song| eval(song)}
    next_songs = (songs[1..-1] || []).map{|song| eval(song)}

    {current: current_song.first, next: next_songs}
  end
end
