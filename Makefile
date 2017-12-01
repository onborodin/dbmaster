# Makefile.in generated by automake 1.15.1 from Makefile.am.
# Makefile.  Generated from Makefile.in by configure.

# Copyright (C) 1994-2017 Free Software Foundation, Inc.

# This Makefile.in is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.





am__is_gnu_make = { \
  if test -z '$(MAKELEVEL)'; then \
    false; \
  elif test -n '$(MAKE_HOST)'; then \
    true; \
  elif test -n '$(MAKE_VERSION)' && test -n '$(CURDIR)'; then \
    true; \
  else \
    false; \
  fi; \
}
am__make_running_with_option = \
  case $${target_option-} in \
      ?) ;; \
      *) echo "am__make_running_with_option: internal error: invalid" \
              "target option '$${target_option-}' specified" >&2; \
         exit 1;; \
  esac; \
  has_opt=no; \
  sane_makeflags=$$MAKEFLAGS; \
  if $(am__is_gnu_make); then \
    sane_makeflags=$$MFLAGS; \
  else \
    case $$MAKEFLAGS in \
      *\\[\ \	]*) \
        bs=\\; \
        sane_makeflags=`printf '%s\n' "$$MAKEFLAGS" \
          | sed "s/$$bs$$bs[$$bs $$bs	]*//g"`;; \
    esac; \
  fi; \
  skip_next=no; \
  strip_trailopt () \
  { \
    flg=`printf '%s\n' "$$flg" | sed "s/$$1.*$$//"`; \
  }; \
  for flg in $$sane_makeflags; do \
    test $$skip_next = yes && { skip_next=no; continue; }; \
    case $$flg in \
      *=*|--*) continue;; \
        -*I) strip_trailopt 'I'; skip_next=yes;; \
      -*I?*) strip_trailopt 'I';; \
        -*O) strip_trailopt 'O'; skip_next=yes;; \
      -*O?*) strip_trailopt 'O';; \
        -*l) strip_trailopt 'l'; skip_next=yes;; \
      -*l?*) strip_trailopt 'l';; \
      -[dEDm]) skip_next=yes;; \
      -[JT]) skip_next=yes;; \
    esac; \
    case $$flg in \
      *$$target_option*) has_opt=yes; break;; \
    esac; \
  done; \
  test $$has_opt = yes
am__make_dryrun = (target_option=n; $(am__make_running_with_option))
am__make_keepgoing = (target_option=k; $(am__make_running_with_option))
pkgdatadir = $(datadir)/pgdumper
pkgincludedir = $(includedir)/pgdumper
pkglibdir = $(libdir)/pgdumper
pkglibexecdir = $(libexecdir)/pgdumper
am__cd = CDPATH="$${ZSH_VERSION+.}$(PATH_SEPARATOR)" && cd
install_sh_DATA = $(install_sh) -c -m 644
install_sh_PROGRAM = $(install_sh) -c
install_sh_SCRIPT = $(install_sh) -c
INSTALL_HEADER = $(INSTALL_DATA)
transform = $(program_transform_name)
NORMAL_INSTALL = :
PRE_INSTALL = :
POST_INSTALL = :
NORMAL_UNINSTALL = :
PRE_UNINSTALL = :
POST_UNINSTALL = :
build_triplet = amd64-unknown-freebsd11.1
host_triplet = amd64-unknown-freebsd11.1
am__append_1 = rc.d/pgmaster
#am__append_2 = pgmaster.service
am__append_3 = pgmaster
am__append_4 = pgmaster.pw.example pgmaster.crt.example pgmaster.key.example
subdir = .
ACLOCAL_M4 = $(top_srcdir)/aclocal.m4
am__aclocal_m4_deps = $(top_srcdir)/acinclude.m4 \
	$(top_srcdir)/configure.ac
am__configure_deps = $(am__aclocal_m4_deps) $(CONFIGURE_DEPENDENCIES) \
	$(ACLOCAL_M4)
DIST_COMMON = $(srcdir)/Makefile.am $(top_srcdir)/configure \
	$(am__configure_deps) $(am__nobase_dist_conf_DATA_DIST) \
	$(am__nobase_dist_pkgdata_DATA_DIST) $(am__DIST_COMMON)
am__CONFIG_DISTCLEAN_FILES = config.status config.cache config.log \
 configure.lineno config.status.lineno
mkinstalldirs = $(install_sh) -d
CONFIG_CLEAN_FILES = pgstore pgagent pgmaster rc.d/pgagent \
	rc.d/pgstore rc.d/pgmaster pgagent.service pgstore.service \
	pgmaster.service
CONFIG_CLEAN_VPATH_FILES =
am__vpath_adj_setup = srcdirstrip=`echo "$(srcdir)" | sed 's|.|.|g'`;
am__vpath_adj = case $$p in \
    $(srcdir)/*) f=`echo "$$p" | sed "s|^$$srcdirstrip/||"`;; \
    *) f=$$p;; \
  esac;
am__strip_dir = f=`echo $$p | sed -e 's|^.*/||'`;
am__install_max = 40
am__nobase_strip_setup = \
  srcdirstrip=`echo "$(srcdir)" | sed 's/[].[^$$\\*|]/\\\\&/g'`
am__nobase_strip = \
  for p in $$list; do echo "$$p"; done | sed -e "s|$$srcdirstrip/||"
am__nobase_list = $(am__nobase_strip_setup); \
  for p in $$list; do echo "$$p $$p"; done | \
  sed "s| $$srcdirstrip/| |;"' / .*\//!s/ .*/ ./; s,\( .*\)/[^/]*$$,\1,' | \
  $(AWK) 'BEGIN { files["."] = "" } { files[$$2] = files[$$2] " " $$1; \
    if (++n[$$2] == $(am__install_max)) \
      { print $$2, files[$$2]; n[$$2] = 0; files[$$2] = "" } } \
    END { for (dir in files) print dir, files[dir] }'
am__base_list = \
  sed '$$!N;$$!N;$$!N;$$!N;$$!N;$$!N;$$!N;s/\n/ /g' | \
  sed '$$!N;$$!N;$$!N;$$!N;s/\n/ /g'
am__uninstall_files_from_dir = { \
  test -z "$$files" \
    || { test ! -d "$$dir" && test ! -f "$$dir" && test ! -r "$$dir"; } \
    || { echo " ( cd '$$dir' && rm -f" $$files ")"; \
         $(am__cd) "$$dir" && rm -f $$files; }; \
  }
am__installdirs = "$(DESTDIR)$(etcdir)" "$(DESTDIR)$(sbindir)" \
	"$(DESTDIR)$(confdir)" "$(DESTDIR)$(pkgdatadir)" \
	"$(DESTDIR)$(systemddir)"
SCRIPTS = $(nobase_etc_SCRIPTS) $(sbin_SCRIPTS)
AM_V_P = $(am__v_P_$(V))
am__v_P_ = $(am__v_P_$(AM_DEFAULT_VERBOSITY))
am__v_P_0 = false
am__v_P_1 = :
AM_V_GEN = $(am__v_GEN_$(V))
am__v_GEN_ = $(am__v_GEN_$(AM_DEFAULT_VERBOSITY))
am__v_GEN_0 = @echo "  GEN     " $@;
am__v_GEN_1 = 
AM_V_at = $(am__v_at_$(V))
am__v_at_ = $(am__v_at_$(AM_DEFAULT_VERBOSITY))
am__v_at_0 = @
am__v_at_1 = 
depcomp =
am__depfiles_maybe =
SOURCES =
DIST_SOURCES =
am__can_run_installinfo = \
  case $$AM_UPDATE_INFO_DIR in \
    n|no|NO) false;; \
    *) (install-info --version) >/dev/null 2>&1;; \
  esac
am__nobase_dist_conf_DATA_DIST = pgagent.pw.example pgstore.pw.example \
	pgagent.crt.example pgagent.key.example pgstore.crt.example \
	pgstore.key.example pgmaster.pw.example pgmaster.crt.example \
	pgmaster.key.example
am__nobase_dist_pkgdata_DATA_DIST = pgmaster.sql public/css/app.css \
	public/css/datatables.css public/css/datatables.min.css \
	public/css/foundation-float.css \
	public/css/foundation-float.min.css public/css/foundation.css \
	public/css/foundation.min.css public/favicon.ico \
	public/favicon.png public/icons/foundation-icons.css \
	public/icons/foundation-icons.eot \
	public/icons/foundation-icons.svg \
	public/icons/foundation-icons.ttf \
	public/icons/foundation-icons.woff \
	public/images/sort_asc_disabled.png public/images/sort_asc.png \
	public/images/sort_both.png \
	public/images/sort_desc_disabled.png \
	public/images/sort_desc.png public/js/app.js \
	public/js/datatables.js public/js/datatables.min.js \
	public/js/foundation.js public/js/foundation.min.js \
	public/js/jquery.js public/js/jquery.min.js \
	public/js/what-input.js templs/agent_add.html.ep \
	templs/agent_config.html.ep templs/agent_delete.html.ep \
	templs/agent_list.html.ep templs/agent_db_copy.html.ep \
	templs/agent_db_create.html.ep templs/agent_db_drop.html.ep \
	templs/agent_db_dump.html.ep templs/agent_db_list.html.ep \
	templs/agent_db_rename.html.ep templs/agent_db_restore.html.ep \
	templs/data_list.html.ep templs/exception.development.html.ep \
	templs/exception.production.html.ep templs/hello.html.ep \
	templs/job_list.html.ep templs/login.html.ep \
	templs/not_found.development.html.ep \
	templs/not_found.production.html.ep \
	templs/schedule_add.html.ep templs/schedule_list.html.ep \
	templs/store_add.html.ep templs/store_delete.html.ep \
	templs/store_list.html.ep templs/store_config.html.ep \
	templs/store_data_delete.html.ep \
	templs/store_data_list.html.ep templs/layouts/default.html.ep
DATA = $(nobase_dist_conf_DATA) $(nobase_dist_pkgdata_DATA) \
	$(nobase_systemd_DATA)
am__tagged_files = $(HEADERS) $(SOURCES) $(TAGS_FILES) $(LISP)
am__DIST_COMMON = $(srcdir)/Makefile.in $(srcdir)/pgagent.pl \
	$(srcdir)/pgagent.service.in $(srcdir)/pgmaster.pl \
	$(srcdir)/pgmaster.service.in $(srcdir)/pgstore.pl \
	$(srcdir)/pgstore.service.in $(top_srcdir)/rc.d/pgagent.in \
	$(top_srcdir)/rc.d/pgmaster.in $(top_srcdir)/rc.d/pgstore.in \
	config.guess config.sub install-sh missing
DISTFILES = $(DIST_COMMON) $(DIST_SOURCES) $(TEXINFOS) $(EXTRA_DIST)
distdir = $(PACKAGE)-$(VERSION)
top_distdir = $(distdir)
am__remove_distdir = \
  if test -d "$(distdir)"; then \
    find "$(distdir)" -type d ! -perm -200 -exec chmod u+w {} ';' \
      && rm -rf "$(distdir)" \
      || { sleep 5 && rm -rf "$(distdir)"; }; \
  else :; fi
am__post_remove_distdir = $(am__remove_distdir)
DIST_ARCHIVES = $(distdir).tar.gz
GZIP_ENV = --best
DIST_TARGETS = dist-gzip
distuninstallcheck_listfiles = find . -type f -print
am__distuninstallcheck_listfiles = $(distuninstallcheck_listfiles) \
  | sed 's|^\./|$(prefix)/|' | grep -v '$(infodir)/dir$$'
distcleancheck_listfiles = find . -type f -print
ACLOCAL = ${SHELL} /home/ziggi/pgdumper/head/missing aclocal-1.15
AMTAR = $${TAR-tar}
AM_DEFAULT_VERBOSITY = 1
APP_CONFDIR = /usr/local/etc/pgdumper
APP_EXECDIR = /usr/local/sbin
APP_GROUP = www
APP_LIBDIR = /usr/local/share/pgdumper
APP_LOGDIR = /var/log/pgdumper
APP_RUNDIR = /var/run/pgdumper
APP_USER = www
AUTOCONF = ${SHELL} /home/ziggi/pgdumper/head/missing autoconf
AUTOHEADER = ${SHELL} /home/ziggi/pgdumper/head/missing autoheader
AUTOMAKE = ${SHELL} /home/ziggi/pgdumper/head/missing automake-1.15
AWK = gawk
CYGPATH_W = echo
DEFS = -DPACKAGE_NAME=\"pgdumper\" -DPACKAGE_TARNAME=\"pgdumper\" -DPACKAGE_VERSION=\"0.01\" -DPACKAGE_STRING=\"pgdumper\ 0.01\" -DPACKAGE_BUGREPORT=\"\" -DPACKAGE_URL=\"\" -DPACKAGE=\"pgdumper\" -DVERSION=\"0.01\" -DAPP_CONFDIR=\"/usr/local/etc/pgdumper\" -DAPP_LOGDIR=\"/var/log/pgdumper\" -DAPP_RUNDIR=\"/var/run/pgdumper\" -DPGSTORE_DATADIR=\"/var/pgstore\" -DAPP_USER=\"www\" -DAPP_GROUP=\"www\" -DAPP_LIBDIR=/usr/local/share/pgdumper -DAPP_EXECDIR=/usr/local/sbin
ECHO_C = 
ECHO_N = -n
ECHO_T = 
HAVE_PERL = true
INSTALL = /usr/bin/install -c
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_PROGRAM = ${INSTALL}
INSTALL_SCRIPT = ${INSTALL}
INSTALL_STRIP_PROGRAM = $(install_sh) -c -s
LIBOBJS = 
LIBS = 
LTLIBOBJS = 
MAKEINFO = ${SHELL} /home/ziggi/pgdumper/head/missing makeinfo
MKDIR_P = /usr/local/bin/gmkdir -p
PACKAGE = pgdumper
PACKAGE_BUGREPORT = 
PACKAGE_NAME = pgdumper
PACKAGE_STRING = pgdumper 0.01
PACKAGE_TARNAME = pgdumper
PACKAGE_URL = 
PACKAGE_VERSION = 0.01
PATH_SEPARATOR = :
PERL = /usr/local/bin/perl
PGSTORE_DATADIR = /var/pgstore
ROOT_GROUP = wheel
SET_MAKE = 
SHELL = /bin/sh
STRIP = 
VERSION = 0.01
abs_builddir = /home/ziggi/pgdumper/head
abs_srcdir = /home/ziggi/pgdumper/head
abs_top_builddir = /home/ziggi/pgdumper/head
abs_top_srcdir = /home/ziggi/pgdumper/head
am__leading_dot = .
am__tar = $${TAR-tar} chof - "$$tardir"
am__untar = $${TAR-tar} xf -
bindir = ${exec_prefix}/bin
build = amd64-unknown-freebsd11.1
build_alias = 
build_cpu = amd64
build_os = freebsd11.1
build_vendor = unknown
builddir = .
datadir = ${datarootdir}
datarootdir = ${prefix}/share
docdir = ${datarootdir}/doc/${PACKAGE_TARNAME}
dvidir = ${docdir}
exec_prefix = ${prefix}
host = amd64-unknown-freebsd11.1
host_alias = 
host_cpu = amd64
host_os = freebsd11.1
host_vendor = unknown
htmldir = ${docdir}
includedir = ${prefix}/include
infodir = ${datarootdir}/info
install_sh = ${SHELL} /home/ziggi/pgdumper/head/install-sh
libdir = ${exec_prefix}/lib
libexecdir = ${exec_prefix}/libexec
localedir = ${datarootdir}/locale
localstatedir = ${prefix}/var
mandir = ${datarootdir}/man
mkdir_p = $(MKDIR_P)
oldincludedir = /usr/include
pdfdir = ${docdir}
prefix = /usr/local
program_transform_name = s,x,x,
psdir = ${docdir}
sbindir = ${exec_prefix}/sbin
sharedstatedir = ${prefix}/com
srcdir = .
sysconfdir = ${prefix}/etc
target_alias = 
top_build_prefix = 
top_builddir = .
top_srcdir = .

#
# $Id: Makefile.am 633 2017-04-15 13:51:07Z ziggi $
#
AUTOMAKE_OPTIONS = foreign no-dependencies no-installinfo
EXTRA_DIST = \
	LICENSE

etcdir = /usr/local/etc
nobase_etc_SCRIPTS = rc.d/pgagent rc.d/pgstore \
	$(am__append_1)
#systemddir = /lib/systemd/system
#nobase_systemd_DATA = pgagent.service pgstore.service \
#	$(am__append_2)
sbin_SCRIPTS = pgstore pgagent $(am__append_3)
confdir = /usr/local/etc/pgdumper
nobase_dist_conf_DATA = pgagent.pw.example pgstore.pw.example \
	pgagent.crt.example pgagent.key.example pgstore.crt.example \
	pgstore.key.example $(am__append_4)
nobase_dist_pkgdata_DATA = \
	pgmaster.sql \
	public/css/app.css \
	public/css/datatables.css \
	public/css/datatables.min.css \
	public/css/foundation-float.css \
	public/css/foundation-float.min.css \
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
	templs/agent_db_restore.html.ep \
	\
	templs/data_list.html.ep \
	templs/exception.development.html.ep \
	templs/exception.production.html.ep \
	templs/hello.html.ep \
	templs/job_list.html.ep \
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
	templs/store_data_list.html.ep \
	\
	templs/layouts/default.html.ep

all: all-am

.SUFFIXES:
am--refresh: Makefile
	@:
$(srcdir)/Makefile.in:  $(srcdir)/Makefile.am  $(am__configure_deps)
	@for dep in $?; do \
	  case '$(am__configure_deps)' in \
	    *$$dep*) \
	      echo ' cd $(srcdir) && $(AUTOMAKE) --foreign'; \
	      $(am__cd) $(srcdir) && $(AUTOMAKE) --foreign \
		&& exit 0; \
	      exit 1;; \
	  esac; \
	done; \
	echo ' cd $(top_srcdir) && $(AUTOMAKE) --foreign Makefile'; \
	$(am__cd) $(top_srcdir) && \
	  $(AUTOMAKE) --foreign Makefile
Makefile: $(srcdir)/Makefile.in $(top_builddir)/config.status
	@case '$?' in \
	  *config.status*) \
	    echo ' $(SHELL) ./config.status'; \
	    $(SHELL) ./config.status;; \
	  *) \
	    echo ' cd $(top_builddir) && $(SHELL) ./config.status $@ $(am__depfiles_maybe)'; \
	    cd $(top_builddir) && $(SHELL) ./config.status $@ $(am__depfiles_maybe);; \
	esac;

$(top_builddir)/config.status: $(top_srcdir)/configure $(CONFIG_STATUS_DEPENDENCIES)
	$(SHELL) ./config.status --recheck

$(top_srcdir)/configure:  $(am__configure_deps)
	$(am__cd) $(srcdir) && $(AUTOCONF)
$(ACLOCAL_M4):  $(am__aclocal_m4_deps)
	$(am__cd) $(srcdir) && $(ACLOCAL) $(ACLOCAL_AMFLAGS)
$(am__aclocal_m4_deps):
pgstore: $(top_builddir)/config.status $(srcdir)/pgstore.pl
	cd $(top_builddir) && $(SHELL) ./config.status $@
pgagent: $(top_builddir)/config.status $(srcdir)/pgagent.pl
	cd $(top_builddir) && $(SHELL) ./config.status $@
pgmaster: $(top_builddir)/config.status $(srcdir)/pgmaster.pl
	cd $(top_builddir) && $(SHELL) ./config.status $@
rc.d/pgagent: $(top_builddir)/config.status $(top_srcdir)/rc.d/pgagent.in
	cd $(top_builddir) && $(SHELL) ./config.status $@
rc.d/pgstore: $(top_builddir)/config.status $(top_srcdir)/rc.d/pgstore.in
	cd $(top_builddir) && $(SHELL) ./config.status $@
rc.d/pgmaster: $(top_builddir)/config.status $(top_srcdir)/rc.d/pgmaster.in
	cd $(top_builddir) && $(SHELL) ./config.status $@
pgagent.service: $(top_builddir)/config.status $(srcdir)/pgagent.service.in
	cd $(top_builddir) && $(SHELL) ./config.status $@
pgstore.service: $(top_builddir)/config.status $(srcdir)/pgstore.service.in
	cd $(top_builddir) && $(SHELL) ./config.status $@
pgmaster.service: $(top_builddir)/config.status $(srcdir)/pgmaster.service.in
	cd $(top_builddir) && $(SHELL) ./config.status $@
install-nobase_etcSCRIPTS: $(nobase_etc_SCRIPTS)
	@$(NORMAL_INSTALL)
	@list='$(nobase_etc_SCRIPTS)'; test -n "$(etcdir)" || list=; \
	if test -n "$$list"; then \
	  echo " $(MKDIR_P) '$(DESTDIR)$(etcdir)'"; \
	  $(MKDIR_P) "$(DESTDIR)$(etcdir)" || exit 1; \
	fi; \
	$(am__nobase_strip_setup); \
	for p in $$list; do \
	  if test -f "$$p"; then d=; else d="$(srcdir)/"; fi; \
	  if test -f "$$d$$p"; then echo "$$d$$p"; echo "$$p"; else :; fi; \
	done | \
	sed -e 'p;s,.*/,,;n' \
	    -e "s|$$srcdirstrip/||" -e 'h;s|[^/]*$$||; s|^$$|.|' \
	    -e 'p;x;s,.*/,,;$(transform)' | sed 'N;N;N;s,\n, ,g' | \
	$(AWK) 'BEGIN { files["."] = ""; dirs["."] = 1; } \
	  { d=$$3; if (dirs[d] != 1) { print "d", d; dirs[d] = 1 } \
	    if ($$2 == $$4) { files[d] = files[d] " " $$1; \
	      if (++n[d] == $(am__install_max)) { \
		print "f", d, files[d]; n[d] = 0; files[d] = "" } } \
	    else { print "f", d "/" $$4, $$1 } } \
	  END { for (d in files) print "f", d, files[d] }' | \
	while read type dir files; do \
	  case $$type in \
	  d) echo " $(MKDIR_P) '$(DESTDIR)$(etcdir)/$$dir'"; \
	     $(MKDIR_P) "$(DESTDIR)$(etcdir)/$$dir" || exit $$?;; \
	  f) \
	     if test "$$dir" = .; then dir=; else dir=/$$dir; fi; \
	     test -z "$$files" || { \
	       echo " $(INSTALL_SCRIPT) $$files '$(DESTDIR)$(etcdir)$$dir'"; \
	       $(INSTALL_SCRIPT) $$files "$(DESTDIR)$(etcdir)$$dir" || exit $$?; \
	     } \
	  ;; esac \
	; done

uninstall-nobase_etcSCRIPTS:
	@$(NORMAL_UNINSTALL)
	@list='$(nobase_etc_SCRIPTS)'; test -n "$(etcdir)" || exit 0; \
	$(am__nobase_strip_setup); \
	files=`$(am__nobase_strip) \
	       -e 'h;s,.*/,,;$(transform);x;s|[^/]*$$||;G;s,\n,,'`; \
	dir='$(DESTDIR)$(etcdir)'; $(am__uninstall_files_from_dir)
install-sbinSCRIPTS: $(sbin_SCRIPTS)
	@$(NORMAL_INSTALL)
	@list='$(sbin_SCRIPTS)'; test -n "$(sbindir)" || list=; \
	if test -n "$$list"; then \
	  echo " $(MKDIR_P) '$(DESTDIR)$(sbindir)'"; \
	  $(MKDIR_P) "$(DESTDIR)$(sbindir)" || exit 1; \
	fi; \
	for p in $$list; do \
	  if test -f "$$p"; then d=; else d="$(srcdir)/"; fi; \
	  if test -f "$$d$$p"; then echo "$$d$$p"; echo "$$p"; else :; fi; \
	done | \
	sed -e 'p;s,.*/,,;n' \
	    -e 'h;s|.*|.|' \
	    -e 'p;x;s,.*/,,;$(transform)' | sed 'N;N;N;s,\n, ,g' | \
	$(AWK) 'BEGIN { files["."] = ""; dirs["."] = 1; } \
	  { d=$$3; if (dirs[d] != 1) { print "d", d; dirs[d] = 1 } \
	    if ($$2 == $$4) { files[d] = files[d] " " $$1; \
	      if (++n[d] == $(am__install_max)) { \
		print "f", d, files[d]; n[d] = 0; files[d] = "" } } \
	    else { print "f", d "/" $$4, $$1 } } \
	  END { for (d in files) print "f", d, files[d] }' | \
	while read type dir files; do \
	     if test "$$dir" = .; then dir=; else dir=/$$dir; fi; \
	     test -z "$$files" || { \
	       echo " $(INSTALL_SCRIPT) $$files '$(DESTDIR)$(sbindir)$$dir'"; \
	       $(INSTALL_SCRIPT) $$files "$(DESTDIR)$(sbindir)$$dir" || exit $$?; \
	     } \
	; done

uninstall-sbinSCRIPTS:
	@$(NORMAL_UNINSTALL)
	@list='$(sbin_SCRIPTS)'; test -n "$(sbindir)" || exit 0; \
	files=`for p in $$list; do echo "$$p"; done | \
	       sed -e 's,.*/,,;$(transform)'`; \
	dir='$(DESTDIR)$(sbindir)'; $(am__uninstall_files_from_dir)
install-nobase_dist_confDATA: $(nobase_dist_conf_DATA)
	@$(NORMAL_INSTALL)
	@list='$(nobase_dist_conf_DATA)'; test -n "$(confdir)" || list=; \
	if test -n "$$list"; then \
	  echo " $(MKDIR_P) '$(DESTDIR)$(confdir)'"; \
	  $(MKDIR_P) "$(DESTDIR)$(confdir)" || exit 1; \
	fi; \
	$(am__nobase_list) | while read dir files; do \
	  xfiles=; for file in $$files; do \
	    if test -f "$$file"; then xfiles="$$xfiles $$file"; \
	    else xfiles="$$xfiles $(srcdir)/$$file"; fi; done; \
	  test -z "$$xfiles" || { \
	    test "x$$dir" = x. || { \
	      echo " $(MKDIR_P) '$(DESTDIR)$(confdir)/$$dir'"; \
	      $(MKDIR_P) "$(DESTDIR)$(confdir)/$$dir"; }; \
	    echo " $(INSTALL_DATA) $$xfiles '$(DESTDIR)$(confdir)/$$dir'"; \
	    $(INSTALL_DATA) $$xfiles "$(DESTDIR)$(confdir)/$$dir" || exit $$?; }; \
	done

uninstall-nobase_dist_confDATA:
	@$(NORMAL_UNINSTALL)
	@list='$(nobase_dist_conf_DATA)'; test -n "$(confdir)" || list=; \
	$(am__nobase_strip_setup); files=`$(am__nobase_strip)`; \
	dir='$(DESTDIR)$(confdir)'; $(am__uninstall_files_from_dir)
install-nobase_dist_pkgdataDATA: $(nobase_dist_pkgdata_DATA)
	@$(NORMAL_INSTALL)
	@list='$(nobase_dist_pkgdata_DATA)'; test -n "$(pkgdatadir)" || list=; \
	if test -n "$$list"; then \
	  echo " $(MKDIR_P) '$(DESTDIR)$(pkgdatadir)'"; \
	  $(MKDIR_P) "$(DESTDIR)$(pkgdatadir)" || exit 1; \
	fi; \
	$(am__nobase_list) | while read dir files; do \
	  xfiles=; for file in $$files; do \
	    if test -f "$$file"; then xfiles="$$xfiles $$file"; \
	    else xfiles="$$xfiles $(srcdir)/$$file"; fi; done; \
	  test -z "$$xfiles" || { \
	    test "x$$dir" = x. || { \
	      echo " $(MKDIR_P) '$(DESTDIR)$(pkgdatadir)/$$dir'"; \
	      $(MKDIR_P) "$(DESTDIR)$(pkgdatadir)/$$dir"; }; \
	    echo " $(INSTALL_DATA) $$xfiles '$(DESTDIR)$(pkgdatadir)/$$dir'"; \
	    $(INSTALL_DATA) $$xfiles "$(DESTDIR)$(pkgdatadir)/$$dir" || exit $$?; }; \
	done

uninstall-nobase_dist_pkgdataDATA:
	@$(NORMAL_UNINSTALL)
	@list='$(nobase_dist_pkgdata_DATA)'; test -n "$(pkgdatadir)" || list=; \
	$(am__nobase_strip_setup); files=`$(am__nobase_strip)`; \
	dir='$(DESTDIR)$(pkgdatadir)'; $(am__uninstall_files_from_dir)
install-nobase_systemdDATA: $(nobase_systemd_DATA)
	@$(NORMAL_INSTALL)
	@list='$(nobase_systemd_DATA)'; test -n "$(systemddir)" || list=; \
	if test -n "$$list"; then \
	  echo " $(MKDIR_P) '$(DESTDIR)$(systemddir)'"; \
	  $(MKDIR_P) "$(DESTDIR)$(systemddir)" || exit 1; \
	fi; \
	$(am__nobase_list) | while read dir files; do \
	  xfiles=; for file in $$files; do \
	    if test -f "$$file"; then xfiles="$$xfiles $$file"; \
	    else xfiles="$$xfiles $(srcdir)/$$file"; fi; done; \
	  test -z "$$xfiles" || { \
	    test "x$$dir" = x. || { \
	      echo " $(MKDIR_P) '$(DESTDIR)$(systemddir)/$$dir'"; \
	      $(MKDIR_P) "$(DESTDIR)$(systemddir)/$$dir"; }; \
	    echo " $(INSTALL_DATA) $$xfiles '$(DESTDIR)$(systemddir)/$$dir'"; \
	    $(INSTALL_DATA) $$xfiles "$(DESTDIR)$(systemddir)/$$dir" || exit $$?; }; \
	done

uninstall-nobase_systemdDATA:
	@$(NORMAL_UNINSTALL)
	@list='$(nobase_systemd_DATA)'; test -n "$(systemddir)" || list=; \
	$(am__nobase_strip_setup); files=`$(am__nobase_strip)`; \
	dir='$(DESTDIR)$(systemddir)'; $(am__uninstall_files_from_dir)
tags TAGS:

ctags CTAGS:

cscope cscopelist:


distdir: $(DISTFILES)
	$(am__remove_distdir)
	test -d "$(distdir)" || mkdir "$(distdir)"
	@srcdirstrip=`echo "$(srcdir)" | sed 's/[].[^$$\\*]/\\\\&/g'`; \
	topsrcdirstrip=`echo "$(top_srcdir)" | sed 's/[].[^$$\\*]/\\\\&/g'`; \
	list='$(DISTFILES)'; \
	  dist_files=`for file in $$list; do echo $$file; done | \
	  sed -e "s|^$$srcdirstrip/||;t" \
	      -e "s|^$$topsrcdirstrip/|$(top_builddir)/|;t"`; \
	case $$dist_files in \
	  */*) $(MKDIR_P) `echo "$$dist_files" | \
			   sed '/\//!d;s|^|$(distdir)/|;s,/[^/]*$$,,' | \
			   sort -u` ;; \
	esac; \
	for file in $$dist_files; do \
	  if test -f $$file || test -d $$file; then d=.; else d=$(srcdir); fi; \
	  if test -d $$d/$$file; then \
	    dir=`echo "/$$file" | sed -e 's,/[^/]*$$,,'`; \
	    if test -d "$(distdir)/$$file"; then \
	      find "$(distdir)/$$file" -type d ! -perm -700 -exec chmod u+rwx {} \;; \
	    fi; \
	    if test -d $(srcdir)/$$file && test $$d != $(srcdir); then \
	      cp -fpR $(srcdir)/$$file "$(distdir)$$dir" || exit 1; \
	      find "$(distdir)/$$file" -type d ! -perm -700 -exec chmod u+rwx {} \;; \
	    fi; \
	    cp -fpR $$d/$$file "$(distdir)$$dir" || exit 1; \
	  else \
	    test -f "$(distdir)/$$file" \
	    || cp -p $$d/$$file "$(distdir)/$$file" \
	    || exit 1; \
	  fi; \
	done
	-test -n "$(am__skip_mode_fix)" \
	|| find "$(distdir)" -type d ! -perm -755 \
		-exec chmod u+rwx,go+rx {} \; -o \
	  ! -type d ! -perm -444 -links 1 -exec chmod a+r {} \; -o \
	  ! -type d ! -perm -400 -exec chmod a+r {} \; -o \
	  ! -type d ! -perm -444 -exec $(install_sh) -c -m a+r {} {} \; \
	|| chmod -R a+r "$(distdir)"
dist-gzip: distdir
	tardir=$(distdir) && $(am__tar) | eval GZIP= gzip $(GZIP_ENV) -c >$(distdir).tar.gz
	$(am__post_remove_distdir)

dist-bzip2: distdir
	tardir=$(distdir) && $(am__tar) | BZIP2=$${BZIP2--9} bzip2 -c >$(distdir).tar.bz2
	$(am__post_remove_distdir)

dist-lzip: distdir
	tardir=$(distdir) && $(am__tar) | lzip -c $${LZIP_OPT--9} >$(distdir).tar.lz
	$(am__post_remove_distdir)

dist-xz: distdir
	tardir=$(distdir) && $(am__tar) | XZ_OPT=$${XZ_OPT--e} xz -c >$(distdir).tar.xz
	$(am__post_remove_distdir)

dist-tarZ: distdir
	@echo WARNING: "Support for distribution archives compressed with" \
		       "legacy program 'compress' is deprecated." >&2
	@echo WARNING: "It will be removed altogether in Automake 2.0" >&2
	tardir=$(distdir) && $(am__tar) | compress -c >$(distdir).tar.Z
	$(am__post_remove_distdir)

dist-shar: distdir
	@echo WARNING: "Support for shar distribution archives is" \
	               "deprecated." >&2
	@echo WARNING: "It will be removed altogether in Automake 2.0" >&2
	shar $(distdir) | eval GZIP= gzip $(GZIP_ENV) -c >$(distdir).shar.gz
	$(am__post_remove_distdir)

dist-zip: distdir
	-rm -f $(distdir).zip
	zip -rq $(distdir).zip $(distdir)
	$(am__post_remove_distdir)

dist dist-all:
	$(MAKE) $(AM_MAKEFLAGS) $(DIST_TARGETS) am__post_remove_distdir='@:'
	$(am__post_remove_distdir)

# This target untars the dist file and tries a VPATH configuration.  Then
# it guarantees that the distribution is self-contained by making another
# tarfile.
distcheck: dist
	case '$(DIST_ARCHIVES)' in \
	*.tar.gz*) \
	  eval GZIP= gzip $(GZIP_ENV) -dc $(distdir).tar.gz | $(am__untar) ;;\
	*.tar.bz2*) \
	  bzip2 -dc $(distdir).tar.bz2 | $(am__untar) ;;\
	*.tar.lz*) \
	  lzip -dc $(distdir).tar.lz | $(am__untar) ;;\
	*.tar.xz*) \
	  xz -dc $(distdir).tar.xz | $(am__untar) ;;\
	*.tar.Z*) \
	  uncompress -c $(distdir).tar.Z | $(am__untar) ;;\
	*.shar.gz*) \
	  eval GZIP= gzip $(GZIP_ENV) -dc $(distdir).shar.gz | unshar ;;\
	*.zip*) \
	  unzip $(distdir).zip ;;\
	esac
	chmod -R a-w $(distdir)
	chmod u+w $(distdir)
	mkdir $(distdir)/_build $(distdir)/_build/sub $(distdir)/_inst
	chmod a-w $(distdir)
	test -d $(distdir)/_build || exit 0; \
	dc_install_base=`$(am__cd) $(distdir)/_inst && pwd | sed -e 's,^[^:\\/]:[\\/],/,'` \
	  && dc_destdir="$${TMPDIR-/tmp}/am-dc-$$$$/" \
	  && am__cwd=`pwd` \
	  && $(am__cd) $(distdir)/_build/sub \
	  && ../../configure \
	    $(AM_DISTCHECK_CONFIGURE_FLAGS) \
	    $(DISTCHECK_CONFIGURE_FLAGS) \
	    --srcdir=../.. --prefix="$$dc_install_base" \
	  && $(MAKE) $(AM_MAKEFLAGS) \
	  && $(MAKE) $(AM_MAKEFLAGS) dvi \
	  && $(MAKE) $(AM_MAKEFLAGS) check \
	  && $(MAKE) $(AM_MAKEFLAGS) install \
	  && $(MAKE) $(AM_MAKEFLAGS) installcheck \
	  && $(MAKE) $(AM_MAKEFLAGS) uninstall \
	  && $(MAKE) $(AM_MAKEFLAGS) distuninstallcheck_dir="$$dc_install_base" \
	        distuninstallcheck \
	  && chmod -R a-w "$$dc_install_base" \
	  && ({ \
	       (cd ../.. && umask 077 && mkdir "$$dc_destdir") \
	       && $(MAKE) $(AM_MAKEFLAGS) DESTDIR="$$dc_destdir" install \
	       && $(MAKE) $(AM_MAKEFLAGS) DESTDIR="$$dc_destdir" uninstall \
	       && $(MAKE) $(AM_MAKEFLAGS) DESTDIR="$$dc_destdir" \
	            distuninstallcheck_dir="$$dc_destdir" distuninstallcheck; \
	      } || { rm -rf "$$dc_destdir"; exit 1; }) \
	  && rm -rf "$$dc_destdir" \
	  && $(MAKE) $(AM_MAKEFLAGS) dist \
	  && rm -rf $(DIST_ARCHIVES) \
	  && $(MAKE) $(AM_MAKEFLAGS) distcleancheck \
	  && cd "$$am__cwd" \
	  || exit 1
	$(am__post_remove_distdir)
	@(echo "$(distdir) archives ready for distribution: "; \
	  list='$(DIST_ARCHIVES)'; for i in $$list; do echo $$i; done) | \
	  sed -e 1h -e 1s/./=/g -e 1p -e 1x -e '$$p' -e '$$x'
distuninstallcheck:
	@test -n '$(distuninstallcheck_dir)' || { \
	  echo 'ERROR: trying to run $@ with an empty' \
	       '$$(distuninstallcheck_dir)' >&2; \
	  exit 1; \
	}; \
	$(am__cd) '$(distuninstallcheck_dir)' || { \
	  echo 'ERROR: cannot chdir into $(distuninstallcheck_dir)' >&2; \
	  exit 1; \
	}; \
	test `$(am__distuninstallcheck_listfiles) | wc -l` -eq 0 \
	   || { echo "ERROR: files left after uninstall:" ; \
	        if test -n "$(DESTDIR)"; then \
	          echo "  (check DESTDIR support)"; \
	        fi ; \
	        $(distuninstallcheck_listfiles) ; \
	        exit 1; } >&2
distcleancheck: distclean
	@if test '$(srcdir)' = . ; then \
	  echo "ERROR: distcleancheck can only run from a VPATH build" ; \
	  exit 1 ; \
	fi
	@test `$(distcleancheck_listfiles) | wc -l` -eq 0 \
	  || { echo "ERROR: files left in build directory after distclean:" ; \
	       $(distcleancheck_listfiles) ; \
	       exit 1; } >&2
check-am: all-am
check: check-am
all-am: Makefile $(SCRIPTS) $(DATA)
installdirs:
	for dir in "$(DESTDIR)$(etcdir)" "$(DESTDIR)$(sbindir)" "$(DESTDIR)$(confdir)" "$(DESTDIR)$(pkgdatadir)" "$(DESTDIR)$(systemddir)"; do \
	  test -z "$$dir" || $(MKDIR_P) "$$dir"; \
	done
install: install-am
install-exec: install-exec-am
install-data: install-data-am
uninstall: uninstall-am

install-am: all-am
	@$(MAKE) $(AM_MAKEFLAGS) install-exec-am install-data-am

installcheck: installcheck-am
install-strip:
	if test -z '$(STRIP)'; then \
	  $(MAKE) $(AM_MAKEFLAGS) INSTALL_PROGRAM="$(INSTALL_STRIP_PROGRAM)" \
	    install_sh_PROGRAM="$(INSTALL_STRIP_PROGRAM)" INSTALL_STRIP_FLAG=-s \
	      install; \
	else \
	  $(MAKE) $(AM_MAKEFLAGS) INSTALL_PROGRAM="$(INSTALL_STRIP_PROGRAM)" \
	    install_sh_PROGRAM="$(INSTALL_STRIP_PROGRAM)" INSTALL_STRIP_FLAG=-s \
	    "INSTALL_PROGRAM_ENV=STRIPPROG='$(STRIP)'" install; \
	fi
mostlyclean-generic:

clean-generic:

distclean-generic:
	-test -z "$(CONFIG_CLEAN_FILES)" || rm -f $(CONFIG_CLEAN_FILES)
	-test . = "$(srcdir)" || test -z "$(CONFIG_CLEAN_VPATH_FILES)" || rm -f $(CONFIG_CLEAN_VPATH_FILES)

maintainer-clean-generic:
	@echo "This command is intended for maintainers to use"
	@echo "it deletes files that may require special tools to rebuild."
clean: clean-am

clean-am: clean-generic mostlyclean-am

distclean: distclean-am
	-rm -f $(am__CONFIG_DISTCLEAN_FILES)
	-rm -f Makefile
distclean-am: clean-am distclean-generic

dvi: dvi-am

dvi-am:

html: html-am

html-am:

info: info-am

info-am:

install-data-am: install-nobase_dist_confDATA \
	install-nobase_dist_pkgdataDATA install-nobase_etcSCRIPTS \
	install-nobase_systemdDATA
	@$(NORMAL_INSTALL)
	$(MAKE) $(AM_MAKEFLAGS) install-data-hook
install-dvi: install-dvi-am

install-dvi-am:

install-exec-am: install-sbinSCRIPTS

install-html: install-html-am

install-html-am:

install-info: install-info-am

install-info-am:

install-man:

install-pdf: install-pdf-am

install-pdf-am:

install-ps: install-ps-am

install-ps-am:

installcheck-am:

maintainer-clean: maintainer-clean-am
	-rm -f $(am__CONFIG_DISTCLEAN_FILES)
	-rm -rf $(top_srcdir)/autom4te.cache
	-rm -f Makefile
maintainer-clean-am: distclean-am maintainer-clean-generic

mostlyclean: mostlyclean-am

mostlyclean-am: mostlyclean-generic

pdf: pdf-am

pdf-am:

ps: ps-am

ps-am:

uninstall-am: uninstall-nobase_dist_confDATA \
	uninstall-nobase_dist_pkgdataDATA uninstall-nobase_etcSCRIPTS \
	uninstall-nobase_systemdDATA uninstall-sbinSCRIPTS

.MAKE: install-am install-data-am install-strip

.PHONY: all all-am am--refresh check check-am clean clean-generic \
	cscopelist-am ctags-am dist dist-all dist-bzip2 dist-gzip \
	dist-lzip dist-shar dist-tarZ dist-xz dist-zip distcheck \
	distclean distclean-generic distcleancheck distdir \
	distuninstallcheck dvi dvi-am html html-am info info-am \
	install install-am install-data install-data-am \
	install-data-hook install-dvi install-dvi-am install-exec \
	install-exec-am install-html install-html-am install-info \
	install-info-am install-man install-nobase_dist_confDATA \
	install-nobase_dist_pkgdataDATA install-nobase_etcSCRIPTS \
	install-nobase_systemdDATA install-pdf install-pdf-am \
	install-ps install-ps-am install-sbinSCRIPTS install-strip \
	installcheck installcheck-am installdirs maintainer-clean \
	maintainer-clean-generic mostlyclean mostlyclean-generic pdf \
	pdf-am ps ps-am tags-am uninstall uninstall-am \
	uninstall-nobase_dist_confDATA \
	uninstall-nobase_dist_pkgdataDATA uninstall-nobase_etcSCRIPTS \
	uninstall-nobase_systemdDATA uninstall-sbinSCRIPTS

.PRECIOUS: Makefile


install-data-hook:
	chmod a+x $(DESTDIR)/${etcdir}/rc.d/pgstore
	chmod a+x $(DESTDIR)/${etcdir}/rc.d/pgagent
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(APP_LOGDIR)
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(APP_RUNDIR)
	$(INSTALL) -d -m 750 -o $(APP_USER) -g $(APP_GROUP) $(DESTDIR)$(PGSTORE_DATADIR)
	for data in $(nobase_dist_conf_DATA);do \
	  chmod 0644 $(DESTDIR)$(APP_CONFDIR)/$$data; \
	done

#EOF

# Tell versions [3.59,3.63) of GNU make to not export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
