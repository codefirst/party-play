WebsocketRails::EventMap.describe do
  subscribe :song_changed, to: WebsocketController, with_method: :song_changed
end
