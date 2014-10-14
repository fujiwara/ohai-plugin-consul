ohai-plugin-consul
==================

Ohai plugin for Consul API

Usage
------

via ohai command

```
$ ohai -d /path/to/plugin_dir | jq .consul
```

```json
{
  "agent": {
    "checks": { ... },   #= /v1/agent/checks
    "members": [ ... ],  #= /v1/agent/members
    "services": [ ... ]  #= /v1/agent/services
  },
  "catalog": {
    "datacenters": [ ... ], #= /v1/catalog/datacenters
    "nodes": [ ... ],       #= /v1/catalog/nodes
    "services": [ ... ],    #= /v1/catalog/services
    "node": {},
    "service": {}
  }
  "status": {
    "leader": "...",   #= /v1/status/leader
    "peers": [ ... ],  #= /v1/status/peers
  }
```

via Ohai module in your scripts

```ruby
require 'ohai'
Ohai::Config[:plugin_path] << '/path/to/plugin_dir'
oh = Ohai::System.new
oh.all_plugins
oh[:consul]  #= consul (agent/catalog/status) information
oh[:consul][:catalog][:node]["NODE_NAME"]        #= /v1/catalog/node/NODE_NAME
oh[:consul][:catalog][:service]["SERVICE_NAME"]  #= /v1/catalog/service/SERVICE_NAME
```

via Chef

```ruby
# (client|solo).rb
Ohai::Config[:plugin_path] << '/path/to/plugins'
```

```ruby
# in cookbook
node[:consul]
```

Author
======

Fujiwara Shunichiro <fujiwara.shunichiro@gmail.com>

License
=======

Apache License 2.0
