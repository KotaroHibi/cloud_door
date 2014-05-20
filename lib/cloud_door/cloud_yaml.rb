require 'yaml'
class CloudYaml
  attr_accessor :file, :items, :storage

  def load_yaml
    return false unless File.exist?(@file)
    all_config = YAML.load_file(@file)
    return false unless all_config.is_a?(Hash)
    return false unless all_config.has_key?(@storage)
    config = all_config[@storage]
    @items.each do |item|
      instance_variable_set("@#{item}", config[item]) if config.has_key?(item)
    end
    true
  end

  def update_yaml(update_params)
    if File.exist?(@file)
      all_config = YAML.load_file(@file)
      config     = all_config[@storage]
    else
      all_config = {}
      config     = {}
    end
      @items.each do |item|
      next unless update_params.has_key?(item)
      config[item] = update_params[item]
    end
    all_config[@storage] = config
    open(@file, 'wb') { |f| YAML.dump(all_config, f) }
  end
end
