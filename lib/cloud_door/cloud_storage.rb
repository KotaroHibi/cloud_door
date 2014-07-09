require 'yaml'
require 'open-uri'
require 'date'
require 'zip'
require 'watir-webdriver'
require 'cgi'
require 'cgi/session'
require 'cloud_door/account'
require 'cloud_door/config'
require 'cloud_door/exceptions'
require 'cloud_door/file_list'
require 'cloud_door/token'

module CloudDoor
  class CloudStorage
    attr_accessor :root_id, :storage_name
    # regular expression pattern of parent directory
    PARENT_DIR_PAT = /..\//
    PICK_METHODS = %w(request_user request_dir request_file)

    # there is abstract method. should define there method
    ABSTRACT_METHODS = %w(
      load_token
      login
      request_user
      request_dir
      request_file
      request_download
      request_upload
      request_delete
      request_mkdir
      pull_files
      format_property
    )

    def initialize
      # should make inherited subclass
      raise AbstractClassException
    end

    def method_missing(method, *args)
      if ABSTRACT_METHODS.include?(method.to_s)
        raise AbstractMethodException, "'#{method.to_s}' is abstract method. please define on subclass."
      else
        super
      end
    end

    def set_login_account(login_account)
      @account.login_account = login_account
    end

    def set_login_password(login_password)
      @account.login_password = login_password
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
      @storage_name
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
      session_id = nil
      if @config.session_use?
        cgi        = CGI.new
        session    = CGI::Session.new(cgi)
        session_id = session.session_id
        @token.set_locate(session_id)
        @file_list.set_locate(session_id)
      end
      @token.write_token
      session_id
    rescue => e
      handle_exception(e)
    end

    def show_user
      request_user
    rescue => e
      handle_exception(e)
    end

    def show_files(file_name = nil)
      @file_name = file_name
      raise SetIDException unless set_file_id
      raise NotDirectoryException if file?(file_name)
      pull_files
    rescue => e
      handle_exception(e)
    end

    def change_directory(file_name)
      raise FileNameEmptyException if file_name.nil? || file_name.empty?
      @file_name = file_name
      raise SetIDException unless set_file_id
      raise NotDirectoryException if file?(file_name)
      items = pull_files
      @file_list.write_file_list(items, @file_id, @file_name)
      items
    rescue => e
      handle_exception(e)
    end

    def show_current_dir
      @file_list.pull_current_dir
    end

    def show_property(file_name)
      raise FileNameEmptyException if file_name.nil? || file_name.empty?
      @file_name = file_name
      raise SetIDException unless set_file_id
      unless file_exist?(file_name)
        raise FileNotExistsException, "'#{@file_name}' is not exists on cloud."
      end
      info = request_file
      raise NoDataException if info.nil? || !info.is_a?(Hash)
      format_property(info)
    rescue => e
      handle_exception(e)
    end

    def download_file(file_name)
      raise FileNameEmptyException if file_name.nil? || file_name.empty?
      @file_name = file_name
      raise SetIDException unless set_file_id
      raise NotFileException unless file?(file_name)
      request_download
      File.exist?(@file_name)
    rescue => e
      handle_exception(e)
    end

    def upload_file(file_name)
      @up_file_name = file_name
      raise FileNameEmptyException if @up_file_name.nil? || @up_file_name.empty?
      unless File.exist?(@up_file_name)
        raise FileNotExistsException, "'#{@up_file_name}' is not exists on local."
      end
      @parent_id = pull_parent_id
      up_file = assign_upload_file_name(file_name)
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

    def delete_file(file_name)
      @file_name = file_name
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

    def make_directory(mkdir_name)
      @mkdir_name = mkdir_name
      raise DirectoryNameEmptyException if @mkdir_name.nil? || @mkdir_name.empty?
      @parent_id = pull_parent_id
      # if not raise error, judge that's success
      request_mkdir
      update_file_list
      true
    rescue => e
      handle_exception(e)
    end

    def file_exist?(file_name)
      if file_name =~ PARENT_DIR_PAT
        return !@file_list.top?(file_name)
      end
      @parent_id = pull_parent_id
      items = pull_files
      @parent_id = nil
      return false if items.empty? || !items.is_a?(Hash)
      items.key?(file_name)
    rescue => e
      handle_exception(e)
    end

    def has_file?(file_name)
      raise FileNameEmptyException if file_name.nil? || file_name.empty?
      @file_name = file_name
      raise SetIDException unless set_file_id
      return false if file?(file_name)
      info = show_property(file_name)
      raise NoDataException if info.nil? || !info.is_a?(Hash) || !info.key?('count')
      (info['count'] > 0)
    rescue => e
      handle_exception(e)
    end

    def file?(file_name)
      return false if file_name.nil? || file_name.empty?
      return false if file_name =~ PARENT_DIR_PAT
      properties = @file_list.pull_file_properties(file_name)
      return false unless properties
      properties['type'] == 'file' ? true : false
    end

    def assign_upload_file_name(file_name)
      if File.directory?(file_name)
        "#{file_name}.zip"
      else
        file_name
      end
    end

    private

    def get_session_id
      session_id = nil
      if @config.session_use?
        cgi        = CGI.new
        session    = CGI::Session.new(cgi)
        session_id = session['locate']
      end
      session_id
    end

    def set_file_id
      if @file_name.nil? || @file_name.empty?
        mode = 'current'
      elsif @file_name =~ PARENT_DIR_PAT
        mode = 'parent'
      else
        mode = 'target'
      end
      file_id = @file_list.convert_name_to_id(mode, @file_name)
      return false if file_id.is_a?(FalseClass)
      @file_id = file_id
      true
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

    def pull_parent_id
      parent_id = @file_list.pull_parent_id
      parent_id || @root_id
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
  end
end
