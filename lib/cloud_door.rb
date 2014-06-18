# require 'cloud_door/account'
# require 'cloud_door/cloud_config'
# require 'cloud_door/cloud_storage'
# require 'cloud_door/cloud_yaml'
# require 'cloud_door/console'
# require 'cloud_door/dropbox'
# require 'cloud_door/exceptions'
# require 'cloud_door/file_list'
# require 'cloud_door/onedrive'
# require 'cloud_door/onedrive_api'
# require 'cloud_door/token'
# require 'cloud_door/version'
require './lib/cloud_door/account'
require './lib/cloud_door/cloud_config'
require './lib/cloud_door/cloud_storage'
require './lib/cloud_door/cloud_yaml'
require './lib/cloud_door/console'
require './lib/cloud_door/dropbox'
require './lib/cloud_door/exceptions'
require './lib/cloud_door/file_list'
require './lib/cloud_door/onedrive'
require './lib/cloud_door/onedrive_api'
require './lib/cloud_door/token'
require './lib/cloud_door/version'

module CloudDoor
  class CloudDoor
    attr_reader :storage

    def initialize(storage)
      @storage = storage.new
    end

    def set_file_name(file_name)
      @storage.set_file_name(file_name)
    end

    def set_up_file_name(up_file_name)
      @storage.set_up_file_name(up_file_name)
    end

    def set_mkdir_name(mkdir_name)
      @storage.set_mkdir_name(mkdir_name)
    end

    def login
      @storage.login
    end

    def load_token()
      @storage.load_token
    end

    def reset_token(url)
      @storage.reset_token(url)
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

    def get_cloud_info(target, key = nil)
      @storage.get_cloud_info(target, key)
    end

    def show_files(write = true)
      @storage.show_files(write)
    end

    def show_current_dir
      @storage.show_current_dir
    end

    def show_property
      @storage.show_property
    end

    def delete_file
      @storage.delete_file
    end

    def download_file
      @storage.download_file
    end

    def upload_file
      @storage.upload_file
    end

    def assign_upload_file_name
      @storage.assign_upload_file_name
    end

    def make_directory
      @storage.make_directory
    end

    def delete_file_list
      @storage.delete_file_list
    end

    def file_exists?
      @storage.file_exists?
    end

    def has_file?
      @storage.has_file?
    end

    def file?
      @storage.file?
    end
  end
end
