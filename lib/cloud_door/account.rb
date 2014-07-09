require 'cloud_door/cloud_yaml'

module CloudDoor
  class Account < CloudYaml
    attr_accessor :login_account, :login_password

    ACCOUNT_FILE = 'account.yml'

    ACCOUNT_ITEMS = [
      'login_account',
      'login_password'
    ]

    def initialize(storage, data_path)
      @storage        = storage
      @file           = data_path + ACCOUNT_FILE
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
