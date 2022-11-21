# loki

Enable syslog, do this on each host and replace `target` IP (and maybe `port`) with you syslog `externalIP` that is defined [here](../cluster/apps/monitoring/loki/helmrelease.yaml)

Create file `/etc/rsyslog.d/50-promtail.conf` with the following content:

```bash
module(load="omprog")
module(load="mmutf8fix")
action(type="mmutf8fix" replacementChar="?")
action(type="omfwd" protocol="tcp" target="192.168.42.155" port="1514" Template="RSYSLOG_SyslogProtocol23Format" TCP_Framing="octet-counted" KeepAlive="on")
```

Restart rsyslog and view status

```bash
sudo systemctl restart rsyslog
sudo systemctl status rsyslog
```

In Grafana, on the explore tab, you should now be able to view you hosts logs, e.g. this query `{host="k3s-master"}`
