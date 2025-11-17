# SR Linux EVPN Multi Homing - Layer 3 + DCI

Baseline setup to play with EVPN multi homing (client 2) plus the DCI component (client4 sits in DC2)

Layer 3 multi homing where one ESI is associated with a IP-VRF

Client 2 CE device (linux with FRR) will establish an BGP peering with leaf1 only and share the route 40.40.40.0/24, the ratioanle is that by default leaf3 will only have one path to 40.40.40.0/24 (via leaf1), but an Ethernet segment created at leaf1 and leaf2 (to which CE2 is multi homed) makes it possible to have aliasing to that IP thus allowing for load balancing form leaf3 towards both leaf1 and leaf2 to reach that 40.40.40.0/24 subnet

# Overlay, underlay and mgmt - DC 1

![pic1](https://github.com/missoso/srl-mh-l3-evpn-dci/blob/main/img_and_drawio/underlay_overlay_mgmt-DC1.png)

# Overlay, underlay and mgmt - DC 2

![pic2](https://github.com/missoso/srl-mh-l3-evpn-dci/blob/main/img_and_drawio/underlay_overlay_mgmt-DC2.png)

# Client baseline setup

![pic3](https://github.com/missoso/srl-mh-l3-evpn-dci/blob/main/img_and_drawio/srl-mh-l3-evpn-dci-detail.png)

Symmetric routing on the ip-vrf-12

CE-PE eBGP between client2 and leaf1 only

# Without Ethernet segments

The configurations that are part of this repository have the Ethernet segment already created but if that wasn't the case then from leaf3 there would be one single path to 40.40.40.0/24

```bash
A:leaf3# show route-table
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IPv4 unicast route table of network instance ip-vrf-12
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
+----------------------------------------+-------+------------+----------------------+----------+----------+---------+------------+-------------------------+-------------------------+-------------------------+----------------------------------------------------+
|                 Prefix                 |  ID   | Route Type |     Route Owner      |  Active  |  Origin  | Metric  |    Pref    |     Next-hop (Type)     |   Next-hop Interface    | Backup Next-hop (Type)  |             Backup Next-hop Interface              |
|                                        |       |            |                      |          | Network  |         |            |                         |                         |                         |                                                    |
|                                        |       |            |                      |          | Instance |         |            |                         |                         |                         |                                                    |
+========================================+=======+============+======================+==========+==========+=========+============+=========================+=========================+=========================+====================================================+
| 1.1.1.1/32                             | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32             |                         |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)        |                         |                         |                                                    |
| 2.2.2.2/32                             | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32             |                         |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)        |                         |                         |                                                    |
|                                        |       |            |                      |          |          |         |            | 10.0.1.2/32             |                         |                         |                                                    |
|                                        |       |            |                      |          |          |         |            | (indirect/vxlan)        |                         |                         |                                                    |
| 40.40.40.0/24                          | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32             |                         |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)        |                         |                         |                                                    |
| 172.17.2.0/24                          | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.4/32             |                         |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)        |                         |                         |                                                    |
| 192.168.11.0/31                        | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32             |                         |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)        |                         |                         |                                                    |
| 192.168.12.0/31                        | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.2/32             |                         |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)        |                         |                         |                                                    |
| 192.168.13.0/31                        | 2     | local      | net_inst_mgr         | True     | ip-      | 0       | 0          | 192.168.13.0 (direct)   | ethernet-1/1.0          |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            |                         |                         |                         |                                                    |
| 192.168.13.0/32                        | 2     | host       | net_inst_mgr         | True     | ip-      | 0       | 0          | None (extract)          | None                    |                         |                                                    |
|                                        |       |            |                      |          | vrf-12   |         |            |                         |                         |                         |                                                    |
+----------------------------------------+-------+------------+----------------------+----------+----------+---------+------------+-------------------------+-------------------------+-------------------------+----------------------------------------------------+
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IPv4 routes total                    : 8
IPv4 prefixes with active routes     : 8
IPv4 prefixes with active ECMP routes: 1
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```

# Ethernet segments

With the following Ethernet segment created on both leaf1 and leaf2 (already part of the base configs)

```bash
system {
	network-instance {
            protocols {
                evpn {
                    ethernet-segments {
                        bgp-instance 1 {
                            ethernet-segment ES-2 {
                                type virtual
                                admin-state enable
                                esi 04:02:02:02:02:00:00:00:00:00
                                next-hop 2.2.2.2 {
                                    evi 101 {
                                    }
                                }
                            }
                        }
                    }
                }
                bgp-vpn {
                    bgp-instance 1 {
                    }
                }
            }
        }
}
```

And from leaf3 we now have paths to reach 40.40.40.0/24

```bash
A:leaf3# show route-table
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IPv4 unicast route table of network instance ip-vrf-12
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
+-------------------------------------------+-------+------------+----------------------+----------+----------+---------+------------+--------------------------+--------------------------+--------------------------+---------------------------------------------------------+
|                  Prefix                   |  ID   | Route Type |     Route Owner      |  Active  |  Origin  | Metric  |    Pref    |     Next-hop (Type)      |    Next-hop Interface    |  Backup Next-hop (Type)  |                Backup Next-hop Interface                |
|                                           |       |            |                      |          | Network  |         |            |                          |                          |                          |                                                         |
|                                           |       |            |                      |          | Instance |         |            |                          |                          |                          |                                                         |
+===========================================+=======+============+======================+==========+==========+=========+============+==========================+==========================+==========================+=========================================================+
| 1.1.1.1/32                                | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32              |                          |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)         |                          |                          |                                                         |
| 2.2.2.2/32                                | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32              |                          |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)         |                          |                          |                                                         |
|                                           |       |            |                      |          |          |         |            | 10.0.1.2/32              |                          |                          |                                                         |
|                                           |       |            |                      |          |          |         |            | (indirect/vxlan)         |                          |                          |                                                         |
| 40.40.40.0/24                             | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32              |                          |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)         |                          |                          |                                                         |
|                                           |       |            |                      |          |          |         |            | 10.0.1.2/32              |                          |                          |                                                         |
|                                           |       |            |                      |          |          |         |            | (indirect/vxlan)         |                          |                          |                                                         |
| 172.17.2.0/24                             | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.4/32              |                          |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)         |                          |                          |                                                         |
| 192.168.11.0/31                           | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.1/32              |                          |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)         |                          |                          |                                                         |
| 192.168.12.0/31                           | 0     | bgp-evpn   | bgp_evpn_mgr         | True     | ip-      | 0       | 170        | 10.0.1.2/32              |                          |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            | (indirect/vxlan)         |                          |                          |                                                         |
| 192.168.13.0/31                           | 2     | local      | net_inst_mgr         | True     | ip-      | 0       | 0          | 192.168.13.0 (direct)    | ethernet-1/1.0           |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            |                          |                          |                          |                                                         |
| 192.168.13.0/32                           | 2     | host       | net_inst_mgr         | True     | ip-      | 0       | 0          | None (extract)           | None                     |                          |                                                         |
|                                           |       |            |                      |          | vrf-12   |         |            |                          |                          |                          |                                                         |
+-------------------------------------------+-------+------------+----------------------+----------+----------+---------+------------+--------------------------+--------------------------+--------------------------+---------------------------------------------------------+
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IPv4 routes total                    : 8
IPv4 prefixes with active routes     : 8
IPv4 prefixes with active ECMP routes: 2
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```

## Deploying the lab

The lab is deployed with the [containerlab](https://containerlab.dev) project, where [`mh-l3-evpn-dci.clab.yml`](https://github.com/missoso/srl-symmetric-routing-irb/blob/main/mh-l3-evpn-dci.clab.yml) file declaratively describes the lab topology.

```bash
# change into the cloned directory
# and execute
containerlab deploy --reconfigure
```

To remove the lab:

```bash
containerlab destroy --cleanup
```

## Access the lab

Leaf/spines: SSH through their management IP address or their hostname as defined in the topology file.

```bash
# reach a SR Linux leaf or a spine via SSH
ssh admin@leaf1
ssh admin@spine1
```
Linux clients cannot be reached via SSH, as it is not enabled, but it is possible to connect to them with a docker exec command.

```bash
# reach a Linux client via Docker
docker exec -it client1 bash
```

```bash
╭─────────┬────────────────────────────────────┬─────────┬────────────────╮
│   Name  │             Kind/Image             │  State  │ IPv4/6 Address │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ client1 │ linux                              │ running │ 172.80.80.31   │
│         │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ client2 │ linux                              │ running │ 172.80.80.32   │
│         │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ client3 │ linux                              │ running │ 172.80.80.33   │
│         │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ client4 │ linux                              │ running │ 172.80.80.34   │
│         │ ghcr.io/srl-labs/network-multitool │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ leaf1   │ nokia_srlinux                      │ running │ 172.80.80.11   │
│         │ ghcr.io/nokia/srlinux:24.10.1      │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ leaf2   │ nokia_srlinux                      │ running │ 172.80.80.12   │
│         │ ghcr.io/nokia/srlinux:24.10.1      │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ leaf3   │ nokia_srlinux                      │ running │ 172.80.80.13   │
│         │ ghcr.io/nokia/srlinux:24.10.1      │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ leaf4   │ nokia_srlinux                      │ running │ 172.80.80.14   │
│         │ ghcr.io/nokia/srlinux:24.10.1      │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ spine1  │ nokia_srlinux                      │ running │ 172.80.80.21   │
│         │ ghcr.io/nokia/srlinux:24.10.1      │         │ N/A            │
├─────────┼────────────────────────────────────┼─────────┼────────────────┤
│ spine2  │ nokia_srlinux                      │ running │ 172.80.80.22   │
│         │ ghcr.io/nokia/srlinux:24.10.1      │         │ N/A            │
╰─────────┴────────────────────────────────────┴─────────┴────────────────╯
```


## Linux FRR specifics

To have BGP client 2 is a Linux FRR box, in the clab.yml:
```bash
client2:
      kind: linux
      image: quay.io/frrouting/frr:9.0.2
      binds:
        - configs/ce/ce2.cfg:/etc/frr/frr.conf
        - configs/ce/frr-daemons.conf:/etc/frr/daemons
      mgmt-ipv4: 172.80.80.32
      exec:
        - ip link set eth0 down
      group: server
```

Ethernet0 is disabled since we are not using the mgmt IP

The 1st bind is the startup configuration and the 2nd one is the daemons setup which defines what protocols will be active, in this case:

```bash
bgpd=yes
ospfd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=yes
nhrpd=yes
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=yes
fabricd=no
vrrpd=no
```

To change the configuration use the vtysh command, example:

```bash
:~$ docker exec -it client2 bash

client2:/# vtysh

client2# show running-config 

Building configuration...

Current configuration:
[...]]
```

