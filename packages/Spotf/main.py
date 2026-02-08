#!/usr/bin/env python3
import dbus
import sys

def get_spotify_bus():
    """Connect to Spotify via D-Bus"""
    try:
        bus = dbus.SessionBus()
        spotify = bus.get_object('org.mpris.MediaPlayer2.spotify', '/org/mpris/MediaPlayer2')
        properties = dbus.Interface(spotify, 'org.freedesktop.DBus.Properties')
        player = dbus.Interface(spotify, 'org.mpris.MediaPlayer2.Player')
        return properties, player
    except dbus.exceptions.DBusException as e:
        print(f"Error: Could not connect to Spotify. Is it running?")
        print(f"Details: {e}")
        sys.exit(1)

def get_current_track(short=False):
    """Get information about the currently playing track"""
    properties, _ = get_spotify_bus()

    try:
        metadata = properties.Get('org.mpris.MediaPlayer2.Player', 'Metadata')
        playback_status = properties.Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus')

        title = metadata.get('xesam:title', 'Unknown')
        artist = metadata.get('xesam:artist', ['Unknown'])[0] if metadata.get('xesam:artist') else 'Unknown'
        album = metadata.get('xesam:album', 'Unknown')

        if short:
            track_info = f"{artist} - {title}"
            if len(track_info) > 50:
                track_info = track_info[:47] + "..."

            print(f"{track_info}")
        else:
            print(f"Now Playing:")
            print(f"  Title:  {title}")
            print(f"  Artist: {artist}")
            print(f"  Album:  {album}")
            print(f"  Status: {playback_status}")
    except Exception as e:
        if short:
            print("♫ Spotify")
        else:
            print(f"Error getting track info: {e}")

def get_status():
    properties, _ = get_spotify_bus()
    playback_status = properties.Get('org.mpris.MediaPlayer2.Player', 'PlaybackStatus')

    return playback_status

def play_pause():
    _, player = get_spotify_bus()

    player.PlayPause()
    status = get_status()
    if status == "Playing":
        print("▶")
    else:
        print("⏸")

def next_track():
    _, player = get_spotify_bus()

    player.Next()

def previous_track():
    _, player = get_spotify_bus()

    player.Previous()

def show_help():
    """Display usage information"""
    print("Spotify D-Bus Controller")
    print("\nUsage: python3 spotify_control.py [command] [options]")
    print("\nCommands:")
    print("  current    - Show currently playing track")
    print("  next       - Play next track")
    print("  prev       - Play previous track")
    print("  playpause  - Toggle play/pause")
    print("  help       - Show this help message")
    print("\nOptions:")
    print("  --short    - Use compact output (for i3blocks)")

def main():
    if len(sys.argv) < 2:
        show_help()
        sys.exit(0)

    command = sys.argv[1].lower()
    short_mode = '--short' in sys.argv

    if command == 'current':
        get_current_track(short=short_mode)
    elif command == 'next':
        next_track()
    elif command == 'prev' or command == 'previous':
        previous_track()
    elif command == 'playpause':
        play_pause()
    elif command == 'status':
        get_status()
    elif command == 'help':
        show_help()
    else:
        print(f"Unknown command: {command}")
        show_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
