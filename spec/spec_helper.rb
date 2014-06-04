require 'rubygems'
require 'webmock/rspec'
require 'fabrication'
require 'pp'
require 'cloud_door'
require 'cloud_door/account'
require 'cloud_door/cloud_config'
require 'cloud_door/cloud_yaml'
require 'cloud_door/file_list'
require 'cloud_door/token'

def get_instance_variable_values(target)
  target_hash = {}
  target.instance_variables.each do |item|
    target_hash[item] = target.instance_variable_get(item)
  end
  target_hash
end
