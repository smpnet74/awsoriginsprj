# Create an OSEv3 group that contains the master, nodes, etcd, and lb groups.
# The lb group lets Ansible configure HAProxy as the load balancing solution.
# Comment lb out if your load balancer is pre-configured.
[OSEv3:children]
masters
nodes
etcd
#lb

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
ansible_ssh_user=root
deployment_type=origin
#openshift_hosted_metrics_deploy=false
#openshift_hosted_logging_deploy=false
#containerized=true

# Uncomment the following to enable htpasswd authentication; defaults to
# DenyAllPasswordIdentityProvider.
#openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

# Native high availbility cluster method with optional load balancer.
# If no lb group is defined installer assumes that a load balancer has
# been preconfigured. For installation the value of
# openshift_master_cluster_hostname must resolve to the load balancer
# or to one or all of the masters defined in the inventory if no load
# balancer is present.
#openshift_master_cluster_method=native
#openshift_master_cluster_hostname=${MASTER1}
#openshift_master_cluster_public_hostname=${MASTER1}

# override the default controller lease ttl
#osm_controller_lease_ttl=30

# host group for masters
[masters]
${MASTER1}
#${MASTER2}

# host group for etcd
[etcd]
${MASTER1}
#${MASTER2}

# Specify load balancer host
#[lb]
#${LB1}

# host group for nodes, includes region info
[nodes]
${MASTER1} openshift_node_labels="{'region': 'infra', 'zone': 'default'}" openshift_schedulable=true
${NODE1} openshift_node_labels="{'region': 'primary', 'zone': 'east'}"
${NODE2} openshift_node_labels="{'region': 'primary', 'zone': 'west'}"