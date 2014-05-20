Fabricator(:cloud_config) do
  initialize_with { CloudConfig.new(nil) }
  storage 'onedrive'
  file 'config.yml'
end
