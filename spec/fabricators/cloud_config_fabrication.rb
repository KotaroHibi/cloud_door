Fabricator(:cloud_config, class_name: :'CloudDoor::CloudConfig') do
  initialize_with { CloudDoor::CloudConfig.new(nil) }
  storage 'onedrive'
  file 'config.yml'
end
