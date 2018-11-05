require "spec_helper"
require "serverspec"

package = "prometheus"
service = "prometheus"
user    = "prometheus"
group   = "prometheus"
ports   = [9090]
config_dir = "/etc/prometheus"
log_dir = "/var/log/prometheus"
db_dir  = "/var/lib/prometheus"
extra_packages = %w[]
flags = ""
default_user = "root"
default_group = "root"

case os[:family]
when "freebsd"
  package = "net-mgmt/py-prometheus-client"
  config_dir = "/usr/local/etc"
  db_dir = "/var/db/prometheus"
  extra_packages = %w[net-mgmt/py-prometheus-client]
  flags = 'prometheus_args="--query.max-concurrency=21"'
  default_group = "wheel"
when "ubuntu"
  extra_packages = %w[python-prometheus-client]
  flags = 'ARGS="--query.max-concurrency=21"'
end
config = "#{config_dir}/prometheus.yml"

describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/^# Managed by ansible$/) }
  its(:content_as_yaml) { should include("scrape_configs") }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(db_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/prometheus") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^# Managed by ansible$/) }
    its(:content) { should match(/^#{flags}$/) }
  end
when "ubuntu"
  describe file("/etc/default/prometheus") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/^# Managed by ansible$/) }
    its(:content) { should match(/^#{flags}$/) }
  end

end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
