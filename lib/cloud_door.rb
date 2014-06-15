require 'yaml'
require 'logger'
require 'open-uri'
require 'date'
require 'zip'
require 'rest_client'
require 'watir-webdriver'
require 'cloud_door/version'
require 'cloud_door/account'
require 'cloud_door/cloud_config'
require 'cloud_door/token'
require 'cloud_door/file_list'
require 'cloud_door/exceptions'

module CloudDoor
  class OneDrive
    attr_accessor :token, :file_list, :file_id, :file_name,
                  :up_file_name, :mkdir_name, :parent_id
    attr_reader :config, :account

    # domain for auth
    AUTH_BASE = 'https://login.live.com/'
    # user root file_id
    ROOT_ID = 'me/skydrive'
    # URL for auth
    AUTH_FORMAT = AUTH_BASE +
      'oauth20_authorize.srf?client_id=%s&scope=%s&response_type=code&redirect_uri=%s'
    # URL for get token
    TOKEN_URL = AUTH_BASE + 'oauth20_token.srf'
    # domain for action
    ACTION_BASE = 'https://apis.live.net/v5.0/'
    # URL for get user info
    USER_FORMAT =  ACTION_BASE + 'me?access_token=%s'
    # URL for get directory
    DIR_FORMAT = ACTION_BASE + '%s/files?access_token=%s'
    # URL for get file info
    FILE_FORMAT = ACTION_BASE + '%s?access_token=%s'
    # URL for download file
    DOWNLOAD_FORMAT = ACTION_BASE + '%s/content?suppress_redirects=true&access_token=%s'
    # URL for upload file
    UPLOAD_FORMAT = ACTION_BASE + '%s/files?access_token=%s'
    # URL for delete file
    DELETE_FORMAT = ACTION_BASE + '%s?access_token=%s'
    # URL for make directory
    MKDIR_FORMAT = ACTION_BASE + '%s'
    # update scope
    UPDATE_SCOPE = 'wl.skydrive_update,wl.offline_access'
    # onedrive login site components
    LOGIN_COMPONENTS = {
      'account_text_name'  => 'login',
      'password_text_name' => 'passwd',
      'signin_button_id'   => 'idSIButton9',
      'accept_button_id'   => 'idBtn_Accept'
    }
    # log_file
    LOG_FILE = './log/request.log'
    RESTCLIENT_LOG = './log/request.log'
    # regular expression pattern of parent directory
    PARENT_DIR_PAT = /..\//
    # regular expression pattern of file's file_id
    FILE_ID_PAT = /^file\./
    FILE_PROPERTIES = %w(name id type size created_time updated_time)
    DIRECTORY_PROPERTIRES = %w(name id type size count created_time updated_time)
    TIME_PROPERTY_PAT = /_time$/

    def initialize
      @config    = CloudConfig.new('onedrive')
      @account   = Account.new('onedrive')
      @token     = Token.new
      @file_list = FileList.new
      @file_id   = nil
    end

    def make_auth_url
      AUTH_FORMAT % [@config.client_id, UPDATE_SCOPE, @config.redirect_url]
    end

    def load_token(token_file = '')
      @token = Token.load_token(token_file)
    end

    def reset_token(url)
      info = request_get_token(url)
      return CloudDoor::NoDataException if info.nil?
      return CloudDoor::TokenClassException unless @token.is_a?(Token)
      @token.set_attributes(info)
      @token.write_token
    rescue => e
      handle_exception(e)
    end

    def refresh_token
      info = request_refresh_token
      return CloudDoor::NoDataException if info.nil?
      return CloudDoor::TokenClassException unless @token.is_a?(Token)
      @token.set_attributes(info)
      @token.write_token
    rescue => e
      handle_exception(e)
    end

    def get_cloud_info(target, key = nil)
      if %w(user dir file).include?(target)
        info = send("request_#{target}".to_sym)
      else
        raise CloudDoor::RequestMethodNotFoundException, "request_#{target} is not defined."
      end
      raise CloudDoor::NoDataException if info.nil? || !info.is_a?(Hash)
      key.nil? ? info : pull_onedrive_property(info, key)
    rescue => e
      handle_exception(e)
    end

    def show_files(write = true)
      raise CloudDoor::SetIDException unless set_file_id
      raise CloudDoor::NotDirectoryException if file?
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
      raise CloudDoor::FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise CloudDoor::SetIDException unless set_file_id
      info = get_cloud_info('file')
      format_property(info)
    rescue => e
      handle_exception(e)
    end

    def delete_file
      raise CloudDoor::FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise CloudDoor::SetIDException unless set_file_id
      # if not raise error, judge that's success
      request_delete
      @parent_id = pull_parent_id
      items = pull_files
      @file_list.write_file_list(items)
      true
    rescue => e
      handle_exception(e)
    end

    def download_file
      raise CloudDoor::FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise CloudDoor::SetIDException unless set_file_id
      raise CloudDoor::NotFileException unless file?
      key  = 'location'
      info = request_download
      raise CloudDoor::NoDataException if info.nil? || !info.is_a?(Hash) || !info.key?(key)
      file_url = info[key]
      open("#{@file_name}", 'wb') do |file|
        file << open(file_url).read
      end
      File.exist?(@file_name)
    rescue => e
      handle_exception(e)
    end

    def upload_file
      raise CloudDoor::FileNameEmptyException if @up_file_name.nil? || @up_file_name.empty?
      unless File.exist?(@up_file_name)
        raise CloudDoor::FileNotExistsException, "'#{@up_file_name}' is not exists on local."
      end
      @parent_id = pull_parent_id
      up_file = assign_upload_file_name
      # if not raise error, judge that's success
      request_upload(up_file)
      items = pull_files
      @file_list.write_file_list(items)
      File.delete(up_file) if File.directory?(@up_file_name)
      true
    rescue => e
      unless e.is_a?(CloudDoor::FileNameEmptyException)
        File.delete(up_file) if File.directory?(@up_file_name)
      end
      handle_exception(e)
    end

    def assign_upload_file_name
      if File.directory?(@up_file_name)
        "#{@up_file_name}.zip"
      else
        @up_file_name
      end
    end

    def make_directory
      raise CloudDoor::DirectoryNameEmptyException if @mkdir_name.nil? || @mkdir_name.empty?
      @parent_id = pull_parent_id
      # if not raise error, judge that's success
      request_mkdir
      items = pull_files
      @file_list.write_file_list(items)
      true
    rescue => e
      handle_exception(e)
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
      raise CloudDoor::FileNameEmptyException if @file_name.nil? || @file_name.empty?
      raise CloudDoor::SetIDException unless set_file_id
      return false if file?
      info = show_property
      raise CloudDoor::NoDataException if info.nil? || !info.is_a?(Hash) || !info.key?('size')
      (info['count'] > 0)
    rescue => e
      handle_exception(e)
    end

    def file?
      @file_id =~ FILE_ID_PAT ? true : false
    end

    def login_browser
      browser = Watir::Browser.new :phantomjs
      browser.goto(make_auth_url)
      browser.wait
      browser.text_field(:name, LOGIN_COMPONENTS['account_text_name']).set @account.login_account
      browser.text_field(:name, LOGIN_COMPONENTS['password_text_name']).set @account.login_password
      browser.button(:id, LOGIN_COMPONENTS['signin_button_id']).click
      browser.wait
      browser.button(:id, LOGIN_COMPONENTS['accept_button_id']).click
      browser.wait
      url = browser.url
      browser.close
      url
    rescue => e
      handle_exception(e)
    end

    def self.get_type_from_id(file_id)
      file_id.split('.')[0]
    end

    private

    def pull_files
      dir = get_cloud_info('dir', 'data')
      return {} if dir.nil? || !dir.is_a?(Array) || dir.count == 0
      items = {}
      dir.each do |item|
        items[item['name']] = item['id']
      end
      items
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
      return false if (file_id == false)
      @file_id = file_id
      true
    end

    def pull_parent_id
      parent_id = @file_list.pull_parent_id
      parent_id || ROOT_ID
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

    def send_request(method, url, body = '', header = {})
      # if method == :get
      #   res = RestClient.get(url) do |response, request, result|
      #     request_log(response, request, result)
      #     response
      #   end
      # elsif method == :post
      #   res = RestClient.post(url, body, header) do |response, request, result|
      #     request_log(response, request, result)
      #     response
      #   end
      # elsif method == :delete
      #   res = RestClient.delete(url) do |response, request, result|
      #     request_log(response, request, result)
      #     response
      #   end
      # elsif method == :post_file
      #   res = RestClient.post(url, :file => body) do |response, request, result|
      #     request_log(response, request, result)
      #     response
      #   end
      # end
      if method == :get
        res = RestClient.get(url)
      elsif method == :post
        res = RestClient.post(url, body, header)
      elsif method == :delete
        res = RestClient.delete(url)
      elsif method == :post_file
        res = RestClient.post(url, file: body)
      end
      raise CloudDoor::NoDataException if res.body.nil? || res.body.empty?
      JSON.parse(res.body)
    rescue
      raise
    end

    def request_log(response, request, result)
      logger = Logger.new(LOG_FILE)
      log = "request:\n#{request.args.inspect}\n"
      log << "result:\n#{result.inspect}\n"
      log << "response:\n#{JSON.parse(response.body).inspect}\n"
      logger.info(log)
    end

    def request_get_token(url)
      query  = URI.parse(url).query
      raise CloudDoor::AccessCodeNotIncludeException if query.nil?
      params = CGI.parse(query)
      raise CloudDoor::AccessCodeNotIncludeException unless params.key?('code')
      code = params['code'][0]
      post_body = {
        client_id:     @config.client_id,
        client_secret: @config.client_secret,
        redirect_uri:  @config.redirect_url,
        code:          code,
        grant_type:    'authorization_code'
      }
      header = {content_type: 'application/x-www-form-urlencoded'}
      send_request(:post, TOKEN_URL, post_body, header)
    end

    def request_refresh_token
      post_body = {
        client_id:     @config.client_id,
        client_secret: @config.client_secret,
        redirect_uri:  @config.redirect_url,
        grant_type:    'refresh_token',
        refresh_token: @token.refresh_token
      }
      header = {content_type: 'application/x-www-form-urlencoded'}
      send_request(:post, TOKEN_URL, post_body, header)
    end

    def request_user
      url = USER_FORMAT % @token.access_token
      send_request(:get, url)
    end

    def request_dir
      file_id = @parent_id || @file_id || ROOT_ID
      url = DIR_FORMAT % [file_id, @token.access_token]
      send_request(:get, url)
    end

    def request_file
      url = FILE_FORMAT % [@file_id, @token.access_token]
      send_request(:get, url)
    end

    def request_download
      url = DOWNLOAD_FORMAT % [@file_id, @token.access_token]
      send_request(:get, url)
    end

    def request_upload(file)
      url = UPLOAD_FORMAT % [@parent_id, @token.access_token]
      send_request(:post_file, url, File.new(file, 'rb'))
    end

    def request_delete
      url = DELETE_FORMAT % [@file_id, @token.access_token]
      send_request(:delete, url)
    end

    def request_mkdir
      file_id = @parent_id || ROOT_ID
      url = MKDIR_FORMAT % file_id
      body = JSON('name' => @mkdir_name)
      header = {
        'Authorization' => "Bearer #{@token.access_token}",
        'Content-Type'  => 'application/json'
      }
      send_request(:post, url, body, header)
    end

    def pull_onedrive_property(info, key)
      unless info.key?(key)
        raise CloudDoor::RequestPropertyNotFoundException, "not have '#{key}' property."
      end
      info[key]
    end

    def format_property(info)
      if file?
        properties = FILE_PROPERTIES
      else
        properties = DIRECTORY_PROPERTIRES
      end
      items = {}
      properties.each do |property|
        if property =~ TIME_PROPERTY_PAT
          value = DateTime.parse(info[property]).strftime('%Y-%m-%d %H:%M:%S')
        else
          value = info[property]
        end
        items[property] = value
      end
      items
    end

    def handle_exception(e)
      if e.is_a?(RestClient::Unauthorized)
        raise CloudDoor::UnauthorizedException
      elsif e.class.to_s.include?('RestClient')
        raise CloudDoor::HttpConnectionException
      else
        raise
      end
    end
  end
end
