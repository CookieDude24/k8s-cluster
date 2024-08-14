frontend k3s-frontend
  bind *:6443
  bind *:443
  bind *:80
  mode tcp
  option tcplog
  default_backend k3s-backend

backend k3s-backend
  mode tcp
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s
  server server-1 192.168.1.130:6443 check
  server server-2 192.168.1.131:6443 check
  server server-3 192.168.1.132:6443 check