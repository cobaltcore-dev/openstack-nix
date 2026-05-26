# SSH Access

## Storage VM

```bash
ssh root@localhost -p 2022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

## Controller VM

```bash
ssh root@localhost -p 1122 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

# Cinder & NFS backend

## Create volume

* login in to `controllerVM` or `storageVM`

```bash
openstack volume create --size 4 test_vol
```

* Cinder will create a volume on the mounted nfs share. `/var/lib/cinder/mnt/8216055ab12dc06650bdd79b0d5a6c84`
* The storageVM provides the nfs share itself from `/dev/vdb` mounted on `/exports`

## Assign volume to a VM

* create a new VM with: `openstack server create`
  * or look into system unit: `openstack-create-vm` on VM `controllerVM`

* attach volume to vm

```bash
openstack server list
openstack volume list
openstack server add volume <INSTANCE_NAME_OR_ID> <VOLUME_NAME_OR_ID>
```

* Verify if the nfs store is mounted on the `computeVM`

```bash
[root@computeVM:~]# df -h | grep export
10.0.0.20:/exports        503G  2.0M  503G   1% /var/lib/nova/mnt/8216055ab12dc06650bdd79b0d5a6c84
```

* Verify block device mapping is working in the test VM.

```bash
[root@controllerVM:~]# openstack server list
+--------------------------------------+---------+--------+------------------------+--------+---------+
| ID                                   | Name    | Status | Networks               | Image  | Flavor  |
+--------------------------------------+---------+--------+------------------------+--------+---------+
| fd43f442-d482-49bf-a4d8-a19ac03e36c3 | test_vm | ACTIVE | provider=192.168.44.85 | cirros | m1.nano |
+--------------------------------------+---------+--------+------------------------+--------+---------+

NETNS=$(ip netns list | cut -f 1 -d ' ')
VMIP=$(openstack server show test_vm -f value -c addresses | cut -f 4 -d "'")
ip netns exec $NETNS ssh cirros@${VMIP} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null lsblk

NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
vda     252:0    0  112M  0 disk
|-vda1  252:1    0  103M  0 part /
`-vda15 252:15   0    8M  0 part
vdb     252:16   0    4G  0 disk
```

# Cinder & tgtd backend

## Create volume

* login in to `controllerVM` or `storageVM`

```bash
openstack volume create --size 4 test_vol
```

* Cinder will create a LVM logical volume in the volume group `cinder-volumes`.
* At this time this volume will not be exposed as an iSCSI volume. This only happens when the volume is assigned to a VM.

## Assign volume to a VM

* create a new VM with: `openstack server create`
  * or look into system unit: `openstack-create-vm` on VM `controllerVM`

* attach volume to vm

```bash
openstack server list
openstack volume list
openstack server add volume <INSTANCE_NAME_OR_ID> <VOLUME_NAME_OR_ID>
```

* Verify tgtd status on `storageVM`: `tgt-admin --dump`
* Cinder should generated a tgtd configuration file within: `/var/lib/cinder/volumes`
* In the VM `computeVM` should appear a new block device `sda`. (`dmesg`)

```bash
[root@storageVM:/var/lib/cinder/volumes]# l
total 12K
drwxr-xr-x 2 cinder cinder 4.0K Feb 24 08:16 .
drwxr-xr-x 6 cinder cinder 4.0K Feb 24 08:09 ..
-rw------- 1 cinder cinder  268 Feb 24 08:16 volume-64159e0c-18bb-449f-b1e0-86f198b170e4
```

## Port Forwarding

* Port forwarding is enabled by default for `controllerVM` and `storageVM` and disabled for `computeVM`.
* If multiple computeVMs are used, a separate port must be assigned to each node; otherwise, collisions will occur.

### Default ssh port forwards

* controllerVM: `2022`
* storageVM: `2122`
* computeVM: `n/a`

### Change default ports

```nix

pkgs.nixosTest {

  nodes.controllerVM =
    { ... }:
    {
      openstack-testing.sshHostPort = 2044; # default was: 2022
    };

  nodes.computeVM =
    { ... }:
    {
      openstack-testing.enable = true; # enable / disable all port forwardings
      openstack-testing.sshHostPort = 3022;
    };

  nodes.computeVM2 =
    { ... }:
    {
      openstack-testing.enable = true; # enable / disable all port forwardings
      openstack-testing.sshHostPort = 3122;
    };
}
```
