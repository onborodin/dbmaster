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
	templs/agent_add.html.ep \
	templs/agent_config.html.ep \
	templs/agent_delete.html.ep \
	templs/agent_list.html.ep \
	\
	templs/agent_db_copy.html.ep \
	templs/agent_db_create.html.ep \
	templs/agent_db_drop.html.ep \
	templs/agent_db_dump.html.ep \
	templs/agent_db_list.html.ep \
	templs/agent_db_rename.html.ep \
	templs/agent_db_restore_.html.ep \
	\
	templs/data_list.html.ep \
	templs/exception.development.html.ep \
	templs/exception.production.html.ep \
	templs/hello.html.ep \
	templs/joblist.html.ep \
	templs/login.html.ep \
	templs/not_found.development.html.ep \
	templs/not_found.production.html.ep \
	\
	templs/schedule_add.html.ep \
	templs/schedule_list.html.ep \
	\
	templs/store_add.html.ep \
	templs/store_delete.html.ep \
	templs/store_list.html.ep \
	templs/store_config.html.ep \
	templs/store_data_delete.html.ep \
	templs/store_data_list.html.ep

endif

#EOF
