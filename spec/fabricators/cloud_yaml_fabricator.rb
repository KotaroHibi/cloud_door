Fabricator(:cloud_yaml, class_name: :'CloudDoor::CloudYaml') do
  storage 'onedrive'
  file 'account.yml'
  items %w(login_account login_password)
end
