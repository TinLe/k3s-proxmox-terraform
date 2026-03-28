all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_common_args: -o StrictHostKeyChecking=no
    k3s_version: ${k3s_version}

k3s_cluster:
  children:
    control_plane:
      hosts:
%{ for ip in control_planes ~}
        k3s-cp-${index(control_planes, ip) + 1}:
          ansible_host: ${ip}
%{ endfor ~}
    workers:
      hosts:
%{ for ip in workers ~}
        k3s-worker-${index(workers, ip) + 1}:
          ansible_host: ${ip}
%{ endfor ~}
