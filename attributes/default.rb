#
## Cookbook Name:: appfirst
## Recipe:: default
##
## Copyright 2012, Yipit.com
##
## All rights reserved - Do Not Redistribute
##


case node['platform_family']
when 'rhel'
  default['appfirst']['provider'] = Chef::Provider::Package::Rpm
  default['appfirst']['package'] = "appfirst-#{node['kernel']['machine']}.rpm"
  default['appfirst']['pre_packages'] = %w(openssl098e compat-openldap perl)
when 'debian'
  default['appfirst']['provider'] = Chef::Provider::Package::Dpkg
  default['appfirst']['package'] = "appfirst-#{node['kernel']['machine']}.deb"
  default['appfirst']['pre_packages'] = %w(libssl0.9.8)
end

default['appfirst']['appfirst_account_id'] = '7084'
default['appfirst']['tmp_file_location'] = '/tmp'

