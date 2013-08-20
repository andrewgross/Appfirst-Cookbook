module Appfirst

  def rewrite_alerts(node, appfirst_username, appfirst_api_key)
    require 'rappfirst'
    c = Rappfirst::Client.new(username=appfirst_username, api_key=appfirst_api_key)
    all_alerts = c.alerts

    server_alerts = all_alerts.select do |a|
      normalized_server_name = a.target.gsub('-', '_')
      normalized_node_name = node.name.gsub('-', '_')
      normalized_server_name.include?(normalized_node_name)
    end

    Chef::Log.debug("Found #{server_alerts.count} alerts for #{node.name}")

    update_cpu_alerts(server_alerts) rescue Exception
    update_memory_alerts(server_alerts, node) rescue Exception
    remove_server_down_alerts(server_alerts) rescue Exception
  end

  def update_cpu_alerts(alerts)
    alerts.each do |a|
      if a.trigger_type == "CPU" \
      && a.threshold != 90 \
      && a.time_above_threshold != 180
        a.threshold = 90
        a.time_above_threshold = 180
        Chef::Log.debug("Updating #{a.trigger_type} alerts for #{a.target}")
        a.sync
      end
    end
  end

  def update_memory_alerts(alerts, node)
    system_memory_in_kb = node['memory']['total'].gsub('kB', '')
    system_memory_in_b = system_memory_in_kb.to_i * 1000
    desired_memory_threshold = system_memory_in_b * 0.9

    alerts.each do |a|
      if node.has_key?('roles') && node['roles'].any? { |r| ['bray_worker', 'data_worker', 'ebay_reader'].include?(r) }
        a.delete()
      end

      if a.trigger_type == "Memory" \
      && a.threshold != desired_memory_threshold \
      && a.time_above_threshold != 180
        a.threshold = desired_memory_threshold
        a.time_above_threshold = 180
        Chef::Log.debug("Updating #{a.trigger_type} alerts for #{a.target}")
        a.sync
      end
    end
  end

  def remove_server_down_alerts(alerts)
    alerts.each do |a|
      if a.trigger_type == "Server Down" || a.trigger_type == "Average Response Time"
        Chef::Log.debug("Deleting #{a.trigger_type} alerts for #{a.target}")
        a.delete
      end
    end
  end

  def skip_this_role?(node)
    Chef::Log.debug(node['roles'].inspect)
    node.role?("bray_web")
  end

end