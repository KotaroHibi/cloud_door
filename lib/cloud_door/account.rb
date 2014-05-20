require 'cloud_door/cloud_yaml'
class Account < CloudYaml
  attr_accessor :login_account, :login_password

  ACCOUNT_FILE = 'account.yml'

  ACCOUNT_ITEMS = [
    'login_account',
    'login_password',
  ]

  def initialize(storage)
    @storage        = storage
    @file           = ACCOUNT_FILE
    @items          = ACCOUNT_ITEMS
    @login_account  = ''
    @login_password = ''
    load_yaml
  end
end
