Fabricator(:cloud_yaml) do
  storage 'onedrive'
  file 'account.yml'
  items ['login_account', 'login_password']
end
