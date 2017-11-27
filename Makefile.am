#
# $Id: Makefile.am 633 2017-04-15 13:51:07Z ziggi $
#
AUTOMAKE_OPTIONS = foreign no-dependencies no-installinfo

EXTRA_DIST = \
	LICENSE

install-data-hook:
if FREEBSD_OS
	chmod a+x $(DESTDIR)/${etcdir}/rc.d/pgstore
	chmod a+x $(DESTDIR)/${etcdir}/rc.d/pgagent
endif
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(APP_LOGDIR)
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(APP_RUNDIR)
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(PGSTORE_DATADIR)
	for data in $(nobase_dist_conf_DATA);do \
	  chmod 0644 $(DESTDIR)$(APP_CONFDIR)/$$data; \
	done

if FREEBSD_OS
etcdir = @prefix@/etc
nobase_etc_SCRIPTS = rc.d/pgagent rc.d/pgstore
if PGMASTER
nobase_etc_SCRIPTS += rc.d/pgmaster
endif
endif

if LINUX_OS
systemddir = /lib/systemd/system
nobase_systemd_DATA = pgagent.service pgstore.service
if PGMASTER
nobase_systemd_DATA += pgmaster.service
endif
endif

sbin_SCRIPTS = pgstore pgagent
if PGMASTER
sbin_SCRIPTS += pgmaster
endif

confdir = @APP_CONFDIR@
nobase_dist_conf_DATA = \
	pgagent.pw.example \
	pgstore.pw.example \
	pgagent.crt.example \
	pgagent.key.example \
	pgstore.crt.example \
	pgstore.key.example

if PGMASTER
nobase_dist_conf_DATA += pgmaster.pw.example pgmaster.crt.example pgmaster.key.example
endif

if PGMASTER
nobase_dist_pkgdata_DATA = \
	pgmaster.sql \
	public/css/app.css \
	public/css/datatables.css \
	public/css/datatables.min.css \
	public/css/foundation-float.css \
	public/css/foundation-float.min.css \
	public/css/foundation-prototype.css \
	public/css/foundation-prototype.min.css \
	public/css/foundation-rtl.css \
	public/css/foundation-rtl.min.css \
	public/css/foundation.css \
	public/css/foundation.min.css \
	public/favicon.ico \
	public/favicon.png \
	public/icons/foundation-icons.css \
	public/icons/foundation-icons.eot \
	public/icons/foundation-icons.svg \
	public/icons/foundation-icons.ttf \
	public/icons/foundation-icons.woff \
	public/icons/svgs/fi-address-book.svg \
	public/icons/svgs/fi-alert.svg \
	public/icons/svgs/fi-align-center.svg \
	public/icons/svgs/fi-align-justify.svg \
	public/icons/svgs/fi-align-left.svg \
	public/icons/svgs/fi-align-right.svg \
	public/icons/svgs/fi-anchor.svg \
	public/icons/svgs/fi-annotate.svg \
	public/icons/svgs/fi-archive.svg \
	public/icons/svgs/fi-arrow-down.svg \
	public/icons/svgs/fi-arrow-left.svg \
	public/icons/svgs/fi-arrow-right.svg \
	public/icons/svgs/fi-arrow-up.svg \
	public/icons/svgs/fi-arrows-compress.svg \
	public/icons/svgs/fi-arrows-expand.svg \
	public/icons/svgs/fi-arrows-in.svg \
	public/icons/svgs/fi-arrows-out.svg \
	public/icons/svgs/fi-asl.svg \
	public/icons/svgs/fi-asterisk.svg \
	public/icons/svgs/fi-at-sign.svg \
	public/icons/svgs/fi-background-color.svg \
	public/icons/svgs/fi-battery-empty.svg \
	public/icons/svgs/fi-battery-full.svg \
	public/icons/svgs/fi-battery-half.svg \
	public/icons/svgs/fi-bitcoin-circle.svg \
	public/icons/svgs/fi-bitcoin.svg \
	public/icons/svgs/fi-blind.svg \
	public/icons/svgs/fi-bluetooth.svg \
	public/icons/svgs/fi-bold.svg \
	public/icons/svgs/fi-book-bookmark.svg \
	public/icons/svgs/fi-book.svg \
	public/icons/svgs/fi-bookmark.svg \
	public/icons/svgs/fi-braille.svg \
	public/icons/svgs/fi-burst-new.svg \
	public/icons/svgs/fi-burst-sale.svg \
	public/icons/svgs/fi-burst.svg \
	public/icons/svgs/fi-calendar.svg \
	public/icons/svgs/fi-camera.svg \
	public/icons/svgs/fi-check.svg \
	public/icons/svgs/fi-checkbox.svg \
	public/icons/svgs/fi-clipboard-notes.svg \
	public/icons/svgs/fi-clipboard-pencil.svg \
	public/icons/svgs/fi-clipboard.svg \
	public/icons/svgs/fi-clock.svg \
	public/icons/svgs/fi-closed-caption.svg \
	public/icons/svgs/fi-cloud.svg \
	public/icons/svgs/fi-comment-minus.svg \
	public/icons/svgs/fi-comment-quotes.svg \
	public/icons/svgs/fi-comment-video.svg \
	public/icons/svgs/fi-comment.svg \
	public/icons/svgs/fi-comments.svg \
	public/icons/svgs/fi-compass.svg \
	public/icons/svgs/fi-contrast.svg \
	public/icons/svgs/fi-credit-card.svg \
	public/icons/svgs/fi-crop.svg \
	public/icons/svgs/fi-crown.svg \
	public/icons/svgs/fi-css3.svg \
	public/icons/svgs/fi-database.svg \
	public/icons/svgs/fi-die-five.svg \
	public/icons/svgs/fi-die-four.svg \
	public/icons/svgs/fi-die-one.svg \
	public/icons/svgs/fi-die-six.svg \
	public/icons/svgs/fi-die-three.svg \
	public/icons/svgs/fi-die-two.svg \
	public/icons/svgs/fi-dislike.svg \
	public/icons/svgs/fi-dollar-bill.svg \
	public/icons/svgs/fi-dollar.svg \
	public/icons/svgs/fi-download.svg \
	public/icons/svgs/fi-eject.svg \
	public/icons/svgs/fi-elevator.svg \
	public/icons/svgs/fi-euro.svg \
	public/icons/svgs/fi-eye.svg \
	public/icons/svgs/fi-fast-forward.svg \
	public/icons/svgs/fi-female-symbol.svg \
	public/icons/svgs/fi-female.svg \
	public/icons/svgs/fi-filter.svg \
	public/icons/svgs/fi-first-aid.svg \
	public/icons/svgs/fi-flag.svg \
	public/icons/svgs/fi-folder-add.svg \
	public/icons/svgs/fi-folder-lock.svg \
	public/icons/svgs/fi-folder.svg \
	public/icons/svgs/fi-foot.svg \
	public/icons/svgs/fi-foundation.svg \
	public/icons/svgs/fi-graph-bar.svg \
	public/icons/svgs/fi-graph-horizontal.svg \
	public/icons/svgs/fi-graph-pie.svg \
	public/icons/svgs/fi-graph-trend.svg \
	public/icons/svgs/fi-guide-dog.svg \
	public/icons/svgs/fi-hearing-aid.svg \
	public/icons/svgs/fi-heart.svg \
	public/icons/svgs/fi-home.svg \
	public/icons/svgs/fi-html5.svg \
	public/icons/svgs/fi-indent-less.svg \
	public/icons/svgs/fi-indent-more.svg \
	public/icons/svgs/fi-info.svg \
	public/icons/svgs/fi-italic.svg \
	public/icons/svgs/fi-key.svg \
	public/icons/svgs/fi-laptop.svg \
	public/icons/svgs/fi-layout.svg \
	public/icons/svgs/fi-lightbulb.svg \
	public/icons/svgs/fi-like.svg \
	public/icons/svgs/fi-link.svg \
	public/icons/svgs/fi-list-bullet.svg \
	public/icons/svgs/fi-list-number.svg \
	public/icons/svgs/fi-list-thumbnails.svg \
	public/icons/svgs/fi-list.svg \
	public/icons/svgs/fi-lock.svg \
	public/icons/svgs/fi-loop.svg \
	public/icons/svgs/fi-magnifying-glass.svg \
	public/icons/svgs/fi-mail.svg \
	public/icons/svgs/fi-male-female.svg \
	public/icons/svgs/fi-male-symbol.svg \
	public/icons/svgs/fi-male.svg \
	public/icons/svgs/fi-map.svg \
	public/icons/svgs/fi-marker.svg \
	public/icons/svgs/fi-megaphone.svg \
	public/icons/svgs/fi-microphone.svg \
	public/icons/svgs/fi-minus-circle.svg \
	public/icons/svgs/fi-minus.svg \
	public/icons/svgs/fi-mobile-signal.svg \
	public/icons/svgs/fi-mobile.svg \
	public/icons/svgs/fi-monitor.svg \
	public/icons/svgs/fi-mountains.svg \
	public/icons/svgs/fi-music.svg \
	public/icons/svgs/fi-next.svg \
	public/icons/svgs/fi-no-dogs.svg \
	public/icons/svgs/fi-no-smoking.svg \
	public/icons/svgs/fi-page-add.svg \
	public/icons/svgs/fi-page-copy.svg \
	public/icons/svgs/fi-page-csv.svg \
	public/icons/svgs/fi-page-delete.svg \
	public/icons/svgs/fi-page-doc.svg \
	public/icons/svgs/fi-page-edit.svg \
	public/icons/svgs/fi-page-export-csv.svg \
	public/icons/svgs/fi-page-export-doc.svg \
	public/icons/svgs/fi-page-export-pdf.svg \
	public/icons/svgs/fi-page-export.svg \
	public/icons/svgs/fi-page-filled.svg \
	public/icons/svgs/fi-page-multiple.svg \
	public/icons/svgs/fi-page-pdf.svg \
	public/icons/svgs/fi-page-remove.svg \
	public/icons/svgs/fi-page-search.svg \
	public/icons/svgs/fi-page.svg \
	public/icons/svgs/fi-paint-bucket.svg \
	public/icons/svgs/fi-paperclip.svg \
	public/icons/svgs/fi-pause.svg \
	public/icons/svgs/fi-paw.svg \
	public/icons/svgs/fi-paypal.svg \
	public/icons/svgs/fi-pencil.svg \
	public/icons/svgs/fi-photo.svg \
	public/icons/svgs/fi-play-circle.svg \
	public/icons/svgs/fi-play-video.svg \
	public/icons/svgs/fi-play.svg \
	public/icons/svgs/fi-plus.svg \
	public/icons/svgs/fi-pound.svg \
	public/icons/svgs/fi-power.svg \
	public/icons/svgs/fi-previous.svg \
	public/icons/svgs/fi-price-tag.svg \
	public/icons/svgs/fi-pricetag-multiple.svg \
	public/icons/svgs/fi-print.svg \
	public/icons/svgs/fi-prohibited.svg \
	public/icons/svgs/fi-projection-screen.svg \
	public/icons/svgs/fi-puzzle.svg \
	public/icons/svgs/fi-quote.svg \
	public/icons/svgs/fi-record.svg \
	public/icons/svgs/fi-refresh.svg \
	public/icons/svgs/fi-results-demographics.svg \
	public/icons/svgs/fi-results.svg \
	public/icons/svgs/fi-rewind-ten.svg \
	public/icons/svgs/fi-rewind.svg \
	public/icons/svgs/fi-rss.svg \
	public/icons/svgs/fi-safety-cone.svg \
	public/icons/svgs/fi-save.svg \
	public/icons/svgs/fi-share.svg \
	public/icons/svgs/fi-sheriff-badge.svg \
	public/icons/svgs/fi-shield.svg \
	public/icons/svgs/fi-shopping-bag.svg \
	public/icons/svgs/fi-shopping-cart.svg \
	public/icons/svgs/fi-shuffle.svg \
	public/icons/svgs/fi-skull.svg \
	public/icons/svgs/fi-social-500px.svg \
	public/icons/svgs/fi-social-adobe.svg \
	public/icons/svgs/fi-social-amazon.svg \
	public/icons/svgs/fi-social-android.svg \
	public/icons/svgs/fi-social-apple.svg \
	public/icons/svgs/fi-social-behance.svg \
	public/icons/svgs/fi-social-bing.svg \
	public/icons/svgs/fi-social-blogger.svg \
	public/icons/svgs/fi-social-delicious.svg \
	public/icons/svgs/fi-social-designer-news.svg \
	public/icons/svgs/fi-social-deviant-art.svg \
	public/icons/svgs/fi-social-digg.svg \
	public/icons/svgs/fi-social-dribbble.svg \
	public/icons/svgs/fi-social-drive.svg \
	public/icons/svgs/fi-social-dropbox.svg \
	public/icons/svgs/fi-social-evernote.svg \
	public/icons/svgs/fi-social-facebook.svg \
	public/icons/svgs/fi-social-flickr.svg \
	public/icons/svgs/fi-social-forrst.svg \
	public/icons/svgs/fi-social-foursquare.svg \
	public/icons/svgs/fi-social-game-center.svg \
	public/icons/svgs/fi-social-github.svg \
	public/icons/svgs/fi-social-google-plus.svg \
	public/icons/svgs/fi-social-hacker-news.svg \
	public/icons/svgs/fi-social-hi5.svg \
	public/icons/svgs/fi-social-instagram.svg \
	public/icons/svgs/fi-social-joomla.svg \
	public/icons/svgs/fi-social-lastfm.svg \
	public/icons/svgs/fi-social-linkedin.svg \
	public/icons/svgs/fi-social-medium.svg \
	public/icons/svgs/fi-social-myspace.svg \
	public/icons/svgs/fi-social-orkut.svg \
	public/icons/svgs/fi-social-path.svg \
	public/icons/svgs/fi-social-picasa.svg \
	public/icons/svgs/fi-social-pinterest.svg \
	public/icons/svgs/fi-social-rdio.svg \
	public/icons/svgs/fi-social-reddit.svg \
	public/icons/svgs/fi-social-skillshare.svg \
	public/icons/svgs/fi-social-skype.svg \
	public/icons/svgs/fi-social-smashing-mag.svg \
	public/icons/svgs/fi-social-snapchat.svg \
	public/icons/svgs/fi-social-spotify.svg \
	public/icons/svgs/fi-social-squidoo.svg \
	public/icons/svgs/fi-social-stack-overflow.svg \
	public/icons/svgs/fi-social-steam.svg \
	public/icons/svgs/fi-social-stumbleupon.svg \
	public/icons/svgs/fi-social-treehouse.svg \
	public/icons/svgs/fi-social-tumblr.svg \
	public/icons/svgs/fi-social-twitter.svg \
	public/icons/svgs/fi-social-vimeo.svg \
	public/icons/svgs/fi-social-windows.svg \
	public/icons/svgs/fi-social-xbox.svg \
	public/icons/svgs/fi-social-yahoo.svg \
	public/icons/svgs/fi-social-yelp.svg \
	public/icons/svgs/fi-social-youtube.svg \
	public/icons/svgs/fi-social-zerply.svg \
	public/icons/svgs/fi-social-zurb.svg \
	public/icons/svgs/fi-sound.svg \
	public/icons/svgs/fi-star.svg \
	public/icons/svgs/fi-stop.svg \
	public/icons/svgs/fi-strikethrough.svg \
	public/icons/svgs/fi-subscript.svg \
	public/icons/svgs/fi-superscript.svg \
	public/icons/svgs/fi-tablet-landscape.svg \
	public/icons/svgs/fi-tablet-portrait.svg \
	public/icons/svgs/fi-target-two.svg \
	public/icons/svgs/fi-target.svg \
	public/icons/svgs/fi-telephone-accessible.svg \
	public/icons/svgs/fi-telephone.svg \
	public/icons/svgs/fi-text-color.svg \
	public/icons/svgs/fi-thumbnails.svg \
	public/icons/svgs/fi-ticket.svg \
	public/icons/svgs/fi-torso-business.svg \
	public/icons/svgs/fi-torso-female.svg \
	public/icons/svgs/fi-torso.svg \
	public/icons/svgs/fi-torsos-all-female.svg \
	public/icons/svgs/fi-torsos-all.svg \
	public/icons/svgs/fi-torsos-female-male.svg \
	public/icons/svgs/fi-torsos-male-female.svg \
	public/icons/svgs/fi-torsos.svg \
	public/icons/svgs/fi-trash.svg \
	public/icons/svgs/fi-trees.svg \
	public/icons/svgs/fi-trophy.svg \
	public/icons/svgs/fi-underline.svg \
	public/icons/svgs/fi-universal-access.svg \
	public/icons/svgs/fi-unlink.svg \
	public/icons/svgs/fi-unlock.svg \
	public/icons/svgs/fi-upload-cloud.svg \
	public/icons/svgs/fi-upload.svg \
	public/icons/svgs/fi-usb.svg \
	public/icons/svgs/fi-video.svg \
	public/icons/svgs/fi-volume-none.svg \
	public/icons/svgs/fi-volume-strike.svg \
	public/icons/svgs/fi-volume.svg \
	public/icons/svgs/fi-web.svg \
	public/icons/svgs/fi-wheelchair.svg \
	public/icons/svgs/fi-widget.svg \
	public/icons/svgs/fi-wrench.svg \
	public/icons/svgs/fi-x-circle.svg \
	public/icons/svgs/fi-x.svg \
	public/icons/svgs/fi-yen.svg \
	public/icons/svgs/fi-zoom-in.svg \
	public/icons/svgs/fi-zoom-out.svg \
	public/images/sort_asc_disabled.png \
	public/images/sort_asc.png \
	public/images/sort_both.png \
	public/images/sort_desc_disabled.png \
	public/images/sort_desc.png \
	public/js/app.js \
	public/js/datatables.js \
	public/js/datatables.min.js \
	public/js/foundation.js \
	public/js/foundation.min.js \
	public/js/jquery.js \
	public/js/jquery.min.js \
	public/js/what-input.js \
	\
	templs/agentAdd.html.ep \
	templs/agentConfig.html.ep \
	templs/agentDBCopy.html.ep \
	templs/agentDBCreate.html.ep \
	templs/agentDBDrop.html.ep \
	templs/agentDBDump.html.ep \
	templs/agentDBList.html.ep \
	templs/agentDBRename.html.ep \
	templs/agentDBRestore.html.ep \
	templs/agentDelete.html.ep \
	templs/agentList.html.ep \
	templs/dataList.html.ep \
	templs/exception.development.html.ep \
	templs/exception.production.html.ep \
	templs/hello.html.ep \
	templs/jobList.html.ep \
	templs/layouts/default.html.ep \
	templs/not_found.development.html.ep \
	templs/not_found.production.html.ep \
	templs/storeAdd.html.ep \
	templs/storeConfig.html.ep \
	templs/storeDataList.html.ep \
	templs/storeDataDelete.html.ep \
	templs/storeDelete.html.ep \
	templs/storeList.html.ep \
	\
	templs/scheduleList.html.ep \
	templs/scheduleAdd.html.ep \
	\
	templs/template.html.ep \
	templs/login.html.ep
endif

#EOF
