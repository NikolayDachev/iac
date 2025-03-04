# Network Topology Mapping

This document details the network design, including the spine-leaf architecture with router IDs, VLAN and trunk group configurations, and IP network assignments.

---

## Spine-Leaf and Router IDs

The following YAML snippet describes the spine, spine-leaf, leaf, leaf MLAG, and core router configurations. Each device includes loopback interfaces that serve as router IDs:

```yaml
spine:
  loopback0:  # also router-id
    - 10.0.0.0/24 
    - fd00::1111:10:0:0:0/64

spine_leaf:  # IP network (/31)
  - 10.1.0.0/16
  - fd00::0011:10:1:0:0/64

leaf:
  - loopback0:  # also router-id
      - 10.0.1.0/24 
      - fd00::0001:10:0:1:0/64
  - loopback1:  # shared IP for EVPN
      - 10.0.2.0/24
      - fd00::0002:10:0:2:0/64

leaf_mlag:  # peer (VLAN 4094)
  - 10.0.3.0/30
  - fd00::0003:10:0:3:0/126

core_router:
  router-id:
    - 10.0.4.0/24
    - fd00::0004:10:0:4:0/64
```

---

## VLANs and Trunk Groups

**Note:** For inter-VLAN routing, configurations must be applied on the ```CoreRouter``` trunk group.

- **Leaf Switch Consideration:** On leaf switches (e.g., leaf1, leaf3, leaf5), PO interfaces (905 for Ceph and 908 for PVE) must have native VLAN 10 (BareMetal) for PXE boot.

The table below summarizes the trunk groups along with their IDs, names, and descriptions:

| Trunk Groups                         | ID   | Name          | Description                                      |
|--------------------------------------|------|---------------|--------------------------------------------------|
| MLAG                                 | 4094 | MLAG          | MLAG peering VLAN                                |
| Pve, Ceph, CoreRouter, BareMetal, MLAG| 10   | BareMetal     | DHCP/PXE install (chicken)                   |
| Ceph, CoreRouter, MLAG               | 20   | CEPH          | Ceph client                                      |
| CephOSD, MLAG                        | 21   | CEPH_OSD      | Ceph OSD network                                 |
| Pve, CoreRouter, MLAG                | 30   | PVE_MGMT      | PVE management VLAN (access to web interface)    |
| PveCluster, MLAG                     | 31   | PVE_CLUSTER   | PVE cluster                                      |
| PveCephOSD, MLAG                     | 32   | PVE_CEPH_OSD  | PVE Ceph OSD network                             |
| Pve, CoreRouter, MLAG                | 100  | PVE_Internal  | Internal VMs                                     |
| Pve, CoreRouter, MLAG                | 101  | PVE_DMZ       | DMZ server VMs                                   |

---

## IP Networks

The following YAML snippet defines the IP networks for each VLAN.  
**Note:** If inter-VLAN routing is required, ensure that configurations are applied to the ```CoreRouter``` trunk group.  
**Note:** The IPv6 networks in this document serve as a guide for how to add IPv6 configurations to your nodes.  
```yaml
- name: "MLAG"
  vlan_id: 4094
  net:
    - "{{ leaf_mlag }}"

- name: "BareMetal"
  vlan_id: 10
  net:
    ip4: "172.16.10.0/24"
    gw4: "172.16.10.254"
    ip6: "fd00::0005:172:16:10:0/64"
    gw6: "fd00::0005:ffff:ffff:ffff:ffff"

- name: "Ceph"
  vlan_id: 20
  net:
    ip4: "172.16.20.0/24"
    gw4: "172.16.20.254"
    ip6: "fd00::0006:172:16:20:0/64"
    gw6: "fd00::0006:ffff:ffff:ffff:ffff"

- name: "CephOSD - unrouted"
  vlan_id: 21
  net:
    ip4: "172.16.21.0/24"
    ip6: "fd00::fff6:172:16:21:0/64"

- name: "Pve"
  vlan_id: 30
  net:
    ip4: "172.16.30.0/24"
    gw4: "172.16.30.254"
    ip6: "fd00::0007:172:16:30:0/64"
    gw6: "fd00::0007:ffff:ffff:ffff:ffff"

- name: "PveCluster - unrouted"
  vlan_id: 31
  net:
    ip4: "172.16.31.0/24"
    ip6: "fd00::ffe7:172:16:31:0/64"

- name: "PveCephOSD - unrouted"
  vlan_id: 32
  net:
    ip4: "172.16.32.0/24"
    ip6: "fd00::fff7:172:16:32:0/64"

- name: "Pve_Internal"
  vlan_id: 100
  net:
    ip4: "172.16.100.0/24"
    gw4: "172.16.100.254"
    ip6: "fd00::0008:172:16:100:0/64"
    gw6: "fd00::0008:ffff:ffff:ffff:ffff"

- name: "Pve_DMZ"
  vlan_id: 101
  net:
    ip4: "172.16.101.0/24"
    gw4: "172.16.101.254"
    ip6: "fd00::0009:172:16:101:0/64"
    gw6: "fd00::0009:ffff:ffff:ffff:ffff"
```

