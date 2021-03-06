TERMUX_PKG_HOMEPAGE=https://www.musicpd.org
TERMUX_PKG_DESCRIPTION="Music player daemon"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_VERSION=0.21.18
TERMUX_PKG_SRCURL=https://github.com/MusicPlayerDaemon/MPD/archive/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=1afe30f3103bede6b9da5b107bc1d689fbc3324df94cdf00cafa8c7e50e9eee4
TERMUX_PKG_DEPENDS="libc++, libcurl, libid3tag, libopus, pulseaudio, libmpdclient, openal-soft, libvorbis, libsqlite, ffmpeg, libmp3lame, libbz2, libogg, libnfs, zlib"
TERMUX_PKG_BUILD_DEPENDS="boost"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dalsa=disabled
-Dao=disabled
-Depoll=false
-Dexpat=disabled
-Diconv=disabled
-Dicu=disabled
-Dmad=disabled
-Dpcre=disabled
-Dsndio=disabled
"
TERMUX_PKG_CONFFILES="etc/mpd.conf var/service/mpd/run var/service/mpd/log/run"

termux_step_pre_configure() {
	# Certain packages are not safe to build on device because their
	# build.sh script deletes specific files in $TERMUX_PREFIX.
	if $TERMUX_ON_DEVICE_BUILD; then
		termux_error_exit "Package '$TERMUX_PKG_NAME' is not safe for on-device builds."
	fi

	CXXFLAGS+=" -DTERMUX -UANDROID"
	LDFLAGS+=" -lOpenSLES"
	rm -f $TERMUX_PREFIX/etc/mpd.conf
}

termux_step_post_make_install() {
	install -Dm600 $TERMUX_PKG_SRCDIR/doc/mpdconf.example $TERMUX_PREFIX/etc/mpd.conf

	# Setup mpd service script
	mkdir -p $TERMUX_PREFIX/var/service
	cd $TERMUX_PREFIX/var/service
	mkdir -p mpd/log
	echo "#!$TERMUX_PREFIX/bin/sh" > mpd/run
	echo 'if [ -f "$HOME/.mpd/mpd.conf" ]; then CONFIG="$HOME/.mpd/mpd.conf"; else CONFIG="$PREFIX/etc/mpd.conf"; fi' >> mpd/run
	echo 'exec mpd --stdout --no-daemon $CONFIG 2>&1' >> mpd/run
	chmod +x mpd/run
	touch mpd/down
	ln -sf $PREFIX/share/termux-services/svlogger mpd/log/run
}

termux_step_create_debscripts() {
	echo "#!$TERMUX_PREFIX/bin/sh" > postinst
	echo 'mkdir -p $HOME/.mpd/playlists' >> postinst
}
