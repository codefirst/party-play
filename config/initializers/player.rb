Player = ENV['PLAYER']
Player ||= "afplay" if system("which afplay")
Player ||= "mplayer" if system("which mplayer")
