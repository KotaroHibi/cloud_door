require 'cloud_door/account'
require 'cloud_door/config'
require 'cloud_door/cloud_storage'
require 'cloud_door/cloud_yaml'
require 'cloud_door/console'
require 'cloud_door/dropbox'
require 'cloud_door/exceptions'
require 'cloud_door/file_list'
require 'cloud_door/onedrive'
require 'cloud_door/onedrive_api'
require 'cloud_door/token'
require 'cloud_door/version'

module CloudDoor
  class CloudDoor
    attr_accessor :storage

    def initialize(storage_klass, session_id = nil)
      @storage = storage_klass.new(session_id)
    end

    def login(login_account, login_password)
      @storage.login(login_account, login_password)
    end

    def load_token
      @storage.load_token
    end

    def refresh_token
      @storage.refresh_token
    end

    def show_storage_name
      @storage.show_storage_name
    end

    def show_configuration
      @storage.show_configuration
    end

    def update_configuration(configs)
      @storage.update_configuration(configs)
    end

    def configuration_init?
      @storage.configuration_init?
    end

    def show_account
      @storage.show_account
    end

    def update_account(accounts)
      @storage.update_account(accounts)
    end

    def isset_account?
      @storage.isset_account?
    end

    def show_user
      @storage.show_user
    end

    def show_files(file_name = nil)
      @storage.show_files(file_name)
    end

    def change_directory(file_name)
      @storage.change_directory(file_name)
    end

    def show_current_directory
      @storage.show_current_directory
    end

    def show_property(file_name)
      @storage.show_property(file_name)
    end

    def delete_file(file_name)
      @storage.delete_file(file_name)
    end

    def download_file(file_name)
      @storage.download_file(file_name)
    end

    def upload_file(file_name)
      @storage.upload_file(file_name)
    end

    def make_directory(mkdir_name)
      @storage.make_directory(mkdir_name)
    end

    def file_exist?(file_name)
      @storage.file_exist?(file_name)
    end

    def has_file?(file_name)
      @storage.has_file?(file_name)
    end

    def file?(file_name)
      @storage.file?(file_name)
    end

    def assign_upload_file_name(file_name)
      @storage.assign_upload_file_name(file_name)
    end
  end
end
