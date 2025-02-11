{
  writeText,
  coreutils,
  package,
  filterPath,
  utils_env,
}:
writeText "rootwrap.conf" ''
  # Configuration for neutron-rootwrap
    # This file should be owned by (and only-writeable by) the root user

    [DEFAULT]
    # List of directories to load filter definitions from (separated by ',').
    # These directories MUST all be only writeable by root !
    filters_path=${package}/${filterPath}

    # List of directories to search executables in, in case filters do not
    # explicitly specify a full path (separated by ',')
    # If not specified, defaults to system PATH environment variable.
    # These directories MUST all be only writeable by root !
    exec_dirs=/run/current-system/sw/bin,/${coreutils}/bin,${utils_env}/bin

    # Enable logging to syslog
    # Default value is False
    use_syslog=False

    # Which syslog facility to use.
    # Valid values include auth, authpriv, syslog, local0, local1...
    # Default value is 'syslog'
    syslog_log_facility=syslog

    # Which messages to log.
    # INFO means log all usage
    # ERROR means only log unsuccessful attempts
    syslog_log_level=INFO

    # Rootwrap daemon exits after this seconds of inactivity
    daemon_timeout=600

    # Rootwrap daemon limits itself to that many file descriptors (Linux only)
    rlimit_nofile=1024
''
