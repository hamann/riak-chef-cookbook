#
# Author:: Seth Thomas (<sthomas@basho.com>) and Hector Castro (<hector@basho.com>)
# Cookbook Name:: riak
# Recipe:: default
#
# Copyright (c) 2014 Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
node.default["java"]["jdk_version"] = 7
node.default["java"]["oracle"]["accept_oracle_download_terms"] = true

node.default["sysctl"]["params"]["vm"]["swappiness"] = node["riak"]["sysctl"]["vm"]["swappiness"]
node.default["sysctl"]["params"]["net"]["core"]["somaxconn"] = node["riak"]["sysctl"]["net"]["core"]["somaxconn"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_max_syn_backlog"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_max_syn_backlog"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_sack"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_sack"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_window_scaling"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_window_scaling"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_fin_timeout"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_fin_timeout"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_keepalive_intvl"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_keepalive_intvl"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_tw_reuse"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_tw_reuse"]
node.default["sysctl"]["params"]["net"]["ipv4"]["tcp_moderate_rcvbuf"] = node["riak"]["sysctl"]["net"]["ipv4"]["tcp_moderate_rcvbuf"]

include_recipe "ulimit" unless node["platform_family"] == "debian"
include_recipe "sysctl"
include_recipe "java"

if node["riak"]["package"]["enterprise_key"].empty?
  include_recipe "riak::#{node["riak"]["install_method"]}"
else
  include_recipe "riak::enterprise_package"
end

file "#{node["riak"]["platform_etc_dir"]}/riak.conf" do
  content Cuttlefish.compile("", node["riak"]["config"]).join("\n")
  owner "root"
  mode 0644
  notifies :restart, "service[riak]"
end

if node["platform_family"] == "debian"
  file "/etc/default/riak" do
    content "ulimit -n #{node["riak"]["limits"]["nofile"]}"
    owner "root"
    mode 0644
    action :create
    notifies :restart, "service[riak]"
  end
else
  user_ulimit "riak" do
    filehandle_limit node["riak"]["limits"]["nofile"]
  end
end

node["riak"]["patches"].each do |patch|
  cookbook_file "#{node["riak"]["platform_data_dir"]}/lib/basho-patches/#{patch}" do
    source patch
    owner "root"
    mode 0644
    notifies :restart, "service[riak]"
  end
end

directory node['riak']['data_dir'] do
  owner 'riak'
  group 'riak'
  mode 0755
  action :create
end

service "riak" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [ :enable, :start ]
  not_if { node["riak"]["install_method"] == "source" || node["platform"] == "fedora" }
end
