Fabricator(:token, class_name: :'CloudDoor::Token') do
  initialize_with { CloudDoor::Token.new(token_file, './data/') }
  token_file 'token'
  token_type 'bearer'
  expires_in 3600
  scope 'wl.skydrive'
  access_token 'access_token'
  refresh_token 'refresh_token'
  user_id 1
end
