Fabricator(:account) do
  initialize_with { Account.new(nil) }
  storage 'onedrive'
  file 'account.yml'
end
