INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
# INSTALL PLUGIN scalability_metrics SONAME 'scalability_metrics.so';  # Disabled, until https://bugs.launchpad.net/percona-server/+bug/1441139 is fixed, ref also mail thread 'Re: lp:1441139 (handle_fatal_signal (sig=11) in Queue<PROF_MEASUREMENT>::pop | sql/sql_profile.h:127)'
INSTALL PLUGIN auth_pam SONAME 'auth_pam.so';
INSTALL PLUGIN auth_pam_compat SONAME 'auth_pam_compat.so';
INSTALL PLUGIN auth_socket SONAME 'auth_socket.so';
CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so';
CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so';
CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so';
INSTALL PLUGIN audit_log SONAME 'audit_log.so';
