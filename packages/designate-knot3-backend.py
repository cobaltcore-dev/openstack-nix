# Copyright 2026 CobaltCore contributors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0

"""Remote Knot DNS 3 backend for Designate.

Knot is configured as a secondary for Designate MiniDNS.  This backend only
manages Knot's dynamic zone configuration over SSH; record data is transferred
directly from MiniDNS to Knot using IXFR/AXFR.
"""

import subprocess

from oslo_concurrency import lockutils
from oslo_log import log as logging

from designate.backend import base
from designate import exceptions
from designate import utils


LOG = logging.getLogger(__name__)


class Knot3Backend(base.Backend):
    __plugin_name__ = 'knot3'
    __backend_status__ = 'untested'

    def __init__(self, target):
        super().__init__(target)

        self.ssh = self.options.get('ssh_bin_path', 'ssh')
        self.ssh_host = self.options.get('ssh_host', self.host)
        self.ssh_port = int(self.options.get('ssh_port', 22))
        self.ssh_user = self.options.get('ssh_user', 'designate-knot')
        self.ssh_identity = self.options.get('ssh_identity_file')
        self.ssh_known_hosts = self.options.get(
            'ssh_known_hosts_file', '/etc/ssh/ssh_known_hosts')
        self.knotc = self.options.get('knotc_bin_path', 'knotc')
        self.confdb = self.options.get(
            'confdb_path', '/var/lib/knot/confdb')
        self.socket = self.options.get(
            'control_socket', '/run/knot/knot.sock')
        self.template = self.options.get('template', 'designate')

    def _execute(self, *args):
        command = [
            self.ssh,
            '-o', 'BatchMode=yes',
            '-p', str(self.ssh_port),
        ]
        if self.ssh_identity:
            command.extend(['-i', self.ssh_identity])
        if self.ssh_known_hosts:
            command.extend([
                '-o', 'UserKnownHostsFile=%s' % self.ssh_known_hosts])
        command.extend([
            '--',
            '%s@%s' % (self.ssh_user, self.ssh_host),
            self.knotc,
            # '--confdb=%s' % self.confdb,
            '--socket=%s' % self.socket,
        ])
        command.extend(args)

        try:
            return utils.execute(*command, timeout=self.timeout, run_as_root=False)
        except (utils.processutils.ProcessExecutionError,
                subprocess.TimeoutExpired) as error:
            raise exceptions.Backend(error)

    @lockutils.synchronized('designate-knot3', external=True)
    def _change_config(self, action, zone_name):
        """Change one zone in Knot's persistent configuration database."""
        self._execute('conf-begin')
        try:
            item = 'zone[%s]' % zone_name.rstrip('.')
            self._execute(action, item)
            if action == 'conf-set':
                self._execute(
                    'conf-set', '%s.template' % item, self.template)
            self._execute('conf-commit')
        except Exception:
            try:
                self._execute('conf-abort')
            except exceptions.Backend:
                LOG.exception('Unable to abort the Knot configuration change')
            raise

    def create_zone(self, context, zone):
        LOG.debug('Creating zone %s in Knot', zone.name)
        self._change_config('conf-set', zone.name)

    def update_zone(self, context, zone):
        LOG.debug('Refreshing zone %s in Knot', zone.name)
        self._execute('zone-refresh', zone.name.rstrip('.'))

    def delete_zone(self, context, zone, zone_params=None):
        LOG.debug('Deleting zone %s from Knot', zone.name)
        self._change_config('conf-unset', zone.name)

        # Once the configuration entry is gone, remove the secondary's copy.
        # A failed purge does not mean that the zone is still being served.
        try:
            self._execute(
                '--force', 'zone-purge', zone.name.rstrip('.'), '+orphan')
        except exceptions.Backend:
            LOG.warning('Unable to purge data for Knot zone %s', zone.name)
