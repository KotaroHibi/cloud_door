Fabricator(:account, class_name: :'CloudDoor::Account') do
  initialize_with { CloudDoor::Account.new(nil, './data/') }
  storage 'onedrive'
  file 'account.yml'
end
