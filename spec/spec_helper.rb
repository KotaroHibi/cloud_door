require 'rubygems'
require 'webmock/rspec'
require 'fabrication'
require 'pp'
require 'cloud_door/account'
require 'cloud_door/cloud_config'
require 'cloud_door/cloud_storage'
require 'cloud_door/cloud_yaml'
require 'cloud_door/console'
require 'cloud_door/dropbox'
require 'cloud_door/exceptions'
require 'cloud_door/file_list'
require 'cloud_door/onedrive'
require 'cloud_door/onedrive_api'
require 'cloud_door/token'

# override for test
class HighLine
  attr_accessor :output

  def ask( question, answer_type = String, &details )
    case question
    when 'client_id     : '
      'client'
    when 'client_secret : '
      'secret'
    when 'redirect_url  : '
      'localhost'
    when 'login_account : '
      'account'
    when 'login_password: '
      'password'
    end
  end

  def agree( yes_or_no_question, character = nil )
    if yes_or_no_question.include?("do you want to allow access") ||
       yes_or_no_question.include?("do you want to delete")
      true
    else
      false
    end
  end
end

def get_instance_variable_values(target)
  target_hash = {}
  target.instance_variables.each do |item|
    target_hash[item] = target.instance_variable_get(item)
  end
  target_hash
end

def create_storage(storage_klass, file_id = nil)
  storage = storage_klass.new
  storage.file_id              = file_id
  storage.token.token_file     = './data/test_token'
  storage.token.access_token   = 'token'
  storage.token.refresh_token  = 'refresh'
  storage.config.client_id     = '1234'
  storage.config.client_secret = 'abcd'
  storage.config.redirect_url  = 'testurl'
  storage.file_list.list_file  = './data/testlist'
  storage
end
