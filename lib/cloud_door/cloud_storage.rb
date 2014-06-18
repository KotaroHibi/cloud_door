require 'yaml'
require 'open-uri'
require 'date'
require 'zip'
require 'watir-webdriver'
# require 'cloud_door/version'
# require 'cloud_door/account'
# require 'cloud_door/cloud_config'
# require 'cloud_door/token'
# require 'cloud_door/file_list'
# require 'cloud_door/exceptions'
# require 'cloud_door/version'
require './lib/cloud_door/account'
require './lib/cloud_door/cloud_config'
require './lib/cloud_door/token'
require './lib/cloud_door/file_list'
require './lib/cloud_door/exceptions'
require './lib/cloud_door/version'
require 'pp'

module CloudDoor
  class CloudStorage
    # regular expression pattern of parent directory
    PARENT_DIR_PAT = /..\//
    PICK_METHODS = %w(request_user request_dir request_file)

    def initialize
      # should make inherited subclass
      raise AbstractClassException
    end

    def set_file_name(file_name)
      @file_name = file_name
    end

    def set_up_file_name(up_file_name)
      @up_file_name = up_file_name
    end

    def set_mkdir_name(mkdir_name)
      @mkdir_name = mkdir_name
    end

    def show_storage_name
      STORAGE_NAME
    end

    def show_configuration
      @config
    end

    def update_configuration(configs)
      @config.update_yaml(configs)
    end

    def configuration_init?
      @config.init?
    end

    def show_account
      @account
    end

    def update_account(accounts)
      @account.update_yaml(accounts)
    end

    def isset_account?
      @account.isset_account?
    end

    def reset_token(token_value)
      raise TokenClassException unless @token.is_a?(Token)
      @token.set_attributes(token_value)
      @token.write_token
    rescue => e
      handle_exception(e)
    end

    def show_user
      request_user
    rescue => e
      handle_exception(e)
    end

    def show_files(write = true)
      raise SetIDException unless set_file_id
      raise NotDirectoryException if file?
      items = pull_files
      @file_list.write_file_list(items, @file_id, @file_name) if write
      items
    rescue => e
      handle_exception(e)
    end

    def show_current_dir
      @file_list.pull_current_dir
    end

    def show_property
      raise FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise SetIDException unless set_file_id
      unless file_exists?
        raise FileNotExistsException, "'#{@file_name}' is not exists on cloud."
      end
      info = request_file
      format_property(info)
    rescue => e
      handle_exception(e)
    end

    def pick_cloud_info(method, key)
      if PICK_METHODS.include?(method)
        info = send(method)
      else
        raise RequestMethodNotFoundException, "#{method} is not defined."
      end
      raise NoDataException if info.nil? || !info.is_a?(Hash)
      unless info.key?(key)
        raise RequestPropertyNotFoundException, "not have '#{key}' property."
      end
      info[key]
    rescue => e
      handle_exception(e)
    end

    def download_file
      raise FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise SetIDException unless set_file_id
      raise NotFileException unless file?
      request_download
      File.exist?(@file_name)
    rescue => e
      handle_exception(e)
    end

    def upload_file
      raise FileNameEmptyException if @up_file_name.nil? || @up_file_name.empty?
      unless File.exist?(@up_file_name)
        raise FileNotExistsException, "'#{@up_file_name}' is not exists on local."
      end
      @parent_id = pull_parent_id
      up_file = assign_upload_file_name
      compress_file if File.directory?(@up_file_name)
      # if not raise error, judge that's success
      request_upload(up_file)
      update_file_list
      File.delete(up_file) if File.directory?(@up_file_name)
      true
    rescue => e
      unless e.is_a?(FileNameEmptyException)
        File.delete(up_file) if File.directory?(@up_file_name)
      end
      handle_exception(e)
    end

    def delete_file
      raise FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise SetIDException unless set_file_id
      # if not raise error, judge that's success
      request_delete
      @parent_id = pull_parent_id
      update_file_list
      true
    rescue => e
      handle_exception(e)
    end

    def make_directory
      raise DirectoryNameEmptyException if @mkdir_name.nil? || @mkdir_name.empty?
      @parent_id = pull_parent_id
      # if not raise error, judge that's success
      request_mkdir
      update_file_list
      true
    rescue => e
      handle_exception(e)
    end

    def assign_upload_file_name
      if File.directory?(@up_file_name)
        "#{@up_file_name}.zip"
      else
        @up_file_name
      end
    end

    def delete_file_list
      @file_list.delete_file
    end

    def file_exists?
      if @up_file_name
        file_name = assign_upload_file_name
      elsif @mkdir_name
        file_name = @mkdir_name
      else
        file_name = @file_name
      end
      @parent_id = pull_parent_id
      items = pull_files
      return false if items.empty? || !items.is_a?(Hash)
      items.key?(file_name)
    rescue => e
      handle_exception(e)
    end

    def has_file?
      raise FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise SetIDException unless set_file_id
      return false if file?
      info = show_property
      raise NoDataException if info.nil? || !info.is_a?(Hash) || !info.key?('count')
      (info['count'] > 0)
    rescue => e
      handle_exception(e)
    end

    def file?
      return false if @file_name.nil? || @file_name.empty?
      return false if @file_name =~ PARENT_DIR_PAT
      properties = @file_list.pull_file_properties(@file_name)
      properties['type'] == 'file' ? true : false
    end

    def load_token
      # should override
      raise AbstractMethodException
    end

    def login
      # should override
      raise AbstractMethodException
    end

    private

    def set_file_id
      if @file_name.nil? || @file_name.empty?
        mode = 'current'
      elsif @file_name =~ PARENT_DIR_PAT
        mode = 'parent'
      else
        mode = 'target'
      end
      file_id = @file_list.convert_name_to_id(mode, @file_name)
      return false if (file_id == false)
      @file_id = file_id
      true
    end

    def pull_parent_id
      parent_id = @file_list.pull_parent_id
      parent_id || ROOT_ID
    end

    def update_file_list
      items = pull_files
      @file_list.write_file_list(items)
    end

    def compress_file
      filename = @up_file_name
      zip_file_name = "#{filename}.zip"
      directory = filename
      Zip::File.open(zip_file_name, Zip::File::CREATE) do |zipfile|
        Dir[File.join(directory, '**', '**')].each do |file|
          zipfile.add(file, file)
        end
      end
      zip_file_name
    end

    def handle_exception(e)
      raise
    end

    def request_user
      # should override
      raise AbstractMethodException
    end

    def request_dir
      # should override
      raise AbstractMethodException
    end

    def request_file
      # should override
      raise AbstractMethodException
    end

    def request_download
      # should override
      raise AbstractMethodException
    end

    def request_upload(file_path)
      # should override
      raise AbstractMethodException
    end

    def request_delete
      # should override
      raise AbstractMethodException
    end

    def request_mkdir
      # should override
      raise AbstractMethodException
    end

    def pull_files
      # should override
      raise AbstractMethodException
    end

    def format_property(info)
      # should override
      raise AbstractMethodException
    end
  end
end