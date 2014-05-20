Fabricator(:token) do
  token_file 'token'
  token_type 'bearer'
  expires_in 3600
  scope 'wl.skydrive'
  access_token 'access_token'
  refresh_token 'refresh_token'
  user_id 1
end
