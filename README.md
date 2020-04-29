# Azure Scheduled Events fluentd input plugin

[Fluentd](https://fluentd.org/) input plugin to collect [Azure Scheduled Events](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/scheduled-events).

## Installation

To install Azure Scheduled Events fluentd input plugin on an Azure Virtual Machine with Log Analytics agent installed, copy file ```in_azse.rb``` to folder ```/opt/microsoft/omsagent/plugin/```.

## Configuration

To collect Azure Scheduled Events in Azure Monitor,

1. Add an ```azse.conf``` file like the following to ```/etc/opt/microsoft/omsagent/<workspace id>/conf/omsagent.d/```.

```
<source>
  type azse
  log_level debug
  tag_prefix oms.api
</source>

<filter oms.api.azse.**>
  type record_transformer
  enable_ruby
  <record>
    ResourceName ScheduledEvents
    Computer ${OMS::Common.get_hostname}
    ResourceId ${OMS::Common.get_hostname}
  </record>
</filter>

<match oms.api.azse.**>
  type out_oms_api
  log_level debug

  buffer_chunk_limit 5m
  buffer_type file
  buffer_path /var/opt/microsoft/omsagent/<workspace id>/state/out_oms_api_azse*.buffer
  buffer_queue_limit 10
  flush_interval 20s
  retry_limit 10
  retry_wait 30s
</match>
```

2. Change ownership of the ```azse.conf``` file added under ```/etc/opt/microsoft/omsagent/<workspace id>/conf/omsagent.d/``` with the following command.

```
sudo chown omsagent:omiusers /etc/opt/microsoft/omsagent/conf/omsagent.d/azse.conf
```

3. Restart the Log Analytics agent for Linux service with the following command.

```
sudo /opt/microsoft/omsagent/bin/service_control restart
```

For more details about collecting custom JSON data sources with the Log Analytics agent, please read [this document](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-sources-json).