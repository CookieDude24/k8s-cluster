vrrp_script chk_haproxy {
  script 'killall -0 haproxy' # faster than pidof
  interval 2
}

vrrp_instance haproxy-vip {
  interface eth1
    state MASTER # MASTER on lb-1, BACKUP on lb-2
    priority 200 # 200 on lb-1, 100 on lb-2

    virtual_router_id 51

    virtual_ipaddress {
      192.168.1.128/24
    }

    track_script {
      chk_haproxy
  }
}