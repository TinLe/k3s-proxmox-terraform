k3s_cluster:
  children:
    server:
      hosts:
%{ for ip in control_planes ~}
        ${ip}:
%{ endfor ~}
    agent:
      hosts:
%{ for ip in workers ~}
        ${ip}:
%{ endfor ~}
