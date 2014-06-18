# require 'cloud_door/cloud_yaml'
require './lib/cloud_door/cloud_yaml'
module CloudDoor
  class Account < CloudYaml
    attr_accessor :login_account, :login_password

    ACCOUNT_FILE = './data/account.yml'

    ACCOUNT_ITEMS = [
      'login_account',
      'login_password'
    ]

    def initialize(storage)
      @storage        = storage
      @file           = ACCOUNT_FILE
      @items          = ACCOUNT_ITEMS
      @login_account  = ''
      @login_password = ''
      load_yaml
    end

    def isset_account?
      !(login_account.empty? || login_password.empty?)
    end
  end
end
