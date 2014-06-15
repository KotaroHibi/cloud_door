require 'cloud_door/cloud_yaml'
class CloudConfig < CloudYaml
  attr_accessor :client_id, :client_secret, :redirect_url

  CONFIG_FILE = 'config.yml'

  CONFIG_ITEMS = [
    'client_id',
    'client_secret',
    'redirect_url'
  ]

  def initialize(storage)
    @storage       = storage
    @file          = CONFIG_FILE
    @items         = CONFIG_ITEMS
    @client_id     = ''
    @client_secret = ''
    @redirect_url  = ''
    load_yaml
  end

  def init?
    CONFIG_ITEMS.each do |item|
      val = instance_variable_get("@#{item}")
      return false if val.nil? || val.empty?
    end
    true
  end
end
