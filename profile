# /etc/profile

# System wide environment and startup programs.

appendpath () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

# Set our default path (/usr/sbin:/sbin:/bin included for non-Void chroots)
appendpath '/usr/local/sbin'
appendpath '/usr/local/bin'
appendpath '/usr/bin'
appendpath '/usr/sbin'
appendpath '/sbin'
appendpath '/bin'
unset appendpath

export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"
export PATH="$PATH:$HOME/.local/bin"
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export LIBVA_DRIVER_NAME=i965

# Set default umask
umask 022

# Load profiles from /etc/profile.d
if [ -d /etc/profile.d/ ]; then
	for f in /etc/profile.d/*.sh; do
		[ -r "$f" ] && . "$f"
	done
	unset f
fi

