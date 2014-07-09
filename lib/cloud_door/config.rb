require 'cloud_door/cloud_yaml'

module CloudDoor
  class Config < CloudYaml
    attr_accessor :client_id, :client_secret, :redirect_url
    attr_reader :data_path

    CONFIG_FILE = './cloud_door_config.yml'

    GLOBAL_CONFIG_ITEMS = [
      'data_path',
      'sessoin_flg',
    ]

    CONFIG_ITEMS = [
      'client_id',
      'client_secret',
      'redirect_url'
    ]

    SESSION_FLG_ON  = '1'
    SESSION_FLG_OFF = '0'

    def initialize(storage)
      @storage       = storage
      @data_path     = './data/'
      @session_flg   = SESSION_FLG_OFF
      @file          = CONFIG_FILE
      @items         = CONFIG_ITEMS
      @client_id     = ''
      @client_secret = ''
      @redirect_url  = ''
      load_global_config
      load_yaml
    end

    def load_global_config
      return false unless File.exist?(@file)
      all_config = YAML.load_file(@file)
      return false unless all_config.is_a?(Hash)
      return false unless all_config.key?('global')
      config = all_config['global']
      GLOBAL_CONFIG_ITEMS.each do |item|
        instance_variable_set("@#{item}", config[item]) if config.key?(item)
      end
      true
    end

    def init?
      CONFIG_ITEMS.each do |item|
        val = instance_variable_get("@#{item}")
        return false if val.nil? || val.empty?
      end
      true
    end

    def session_use?
      (@session_flg.to_s == SESSION_FLG_ON.to_s)
    end
  end
end
