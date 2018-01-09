#
# $Id: Makefile.am 633 2017-04-15 13:51:07Z ziggi $
#
AUTOMAKE_OPTIONS = foreign no-dependencies no-installinfo

EXTRA_DIST = \
	LICENSE

install-data-hook:
if FREEBSD_OS
	chmod a+x $(DESTDIR)/${etcdir}/rc.d/dbmaster
endif
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(APP_LOGDIR)
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(APP_RUNDIR)
	for data in $(nobase_conf_DATA);do \
	  chmod 0644 $(DESTDIR)$(APP_CONFDIR)/$$data; \
	done

if FREEBSD_OS
etcdir = @prefix@/etc
nobase_etc_SCRIPTS = rc.d/dbmaster
endif

sbin_SCRIPTS = dbmaster

confdir = @APP_CONFDIR@
dist_conf_DATA = \
	dbmaster.pw.example \
	dbmaster.crt.example \
	dbmaster.conf.example \
	dbmaster.key.example

nobase_dist_pkgdata_DATA = \
	schema.sql \
	\
	public/css/app.css \
	public/css/datatables.css \
	public/css/datatables.min.css \
	public/css/foundation-float.css \
	public/css/foundation-float.min.css \
	public/css/foundation.css \
	public/css/foundation.min.css \
	\
	public/favicon.ico \
	public/favicon.png \
	\
	public/icons/foundation-icons.css \
	public/icons/foundation-icons.eot \
	public/icons/foundation-icons.svg \
	public/icons/foundation-icons.ttf \
	public/icons/foundation-icons.woff \
	public/icons/preview.html \
	\
	public/images/sort_asc_disabled.png \
	public/images/sort_asc.png \
	public/images/sort_both.png \
	public/images/sort_desc_disabled.png \
	public/images/sort_desc.png \
	\
	public/js/app.js \
	public/js/datatables.js \
	public/js/datatables.min.js \
	public/js/foundation.js \
	public/js/foundation.min.js \
	public/js/jquery.js \
	public/js/jquery.min.js \
	public/js/what-input.js \
	\
	templs/exception.development.html.ep \
	templs/exception.production.html.ep \
	templs/layouts/default.html.ep \
	templs/not_found.development.html.ep \
	templs/not_found.production.html.ep \
	templs/hello.html.ep \
	templs/login.html.ep \
	\
	templs/agent-list.html.ep \
	templs/agent-add-form.html.ep \
	templs/agent-add-handler.html.ep \
	templs/agent-rename-form.html.ep \
	templs/agent-rename-handler.html.ep \
	templs/agent-update-form.html.ep \
	templs/agent-update-handler.html.ep \
	templs/agent-delete-form.html.ep \
	templs/agent-delete-handler.html.ep \
	\
	templs/store-list.html.ep \
	templs/store-add-form.html.ep \
	templs/store-add-handler.html.ep \
	templs/store-rename-form.html.ep \
	templs/store-rename-handler.html.ep \
	templs/store-update-form.html.ep \
	templs/store-update-handler.html.ep \
	templs/store-delete-form.html.ep \
	templs/store-delete-handler.html.ep \
	\
	templs/db-list.html.ep \
	templs/db-create-form.html.ep \
	templs/db-create-handler.html.ep \
	templs/db-drop-form.html.ep \
	templs/db-drop-handler.html.ep \
	templs/db-rename-form.html.ep \
	templs/db-rename-handler.html.ep \
	templs/db-dump-form.html.ep \
	templs/db-dump-handler.html.ep \
	templs/db-restore-form.html.ep \
	templs/db-restore-handler.html.ep \
	\
	templs/data-list.html.ep \
	templs/data-delete-form.html.ep \
	templs/data-delete-handler.html.ep \
	\
	templs/schedule-list.html.ep \
	templs/schedule-add-form.html.ep \
	templs/schedule-add-handler.html.ep


#EOF
