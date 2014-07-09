Fabricator(:config, class_name: :'CloudDoor::Config') do
  initialize_with { CloudDoor::Config.new(nil) }
  storage 'onedrive'
  file 'cloud_door_config.yml'
end
