require 'cloud_door/onedrive_api'
require 'cloud_door/cloud_storage'

module CloudDoor
  class OneDrive < CloudStorage
    attr_accessor :token, :file_list, :file_id, :file_name,
                  :up_file_name, :mkdir_name, :parent_id
    attr_reader :config, :account

    # user root file_id
    ROOT_ID = 'me/skydrive'
    # onedrive login site components
    LOGIN_COMPONENTS = {
      'account_text_name'  => 'login',
      'password_text_name' => 'passwd',
      'signin_button_id'   => 'idSIButton9',
      'accept_button_id'   => 'idBtn_Accept'
    }
    TIME_PROPERTY_PAT = /_time$/
    STORAGE_NAME = 'OneDrive'

    def initialize
      @config       = CloudConfig.new('onedrive')
      @account      = Account.new('onedrive')
      @token        = Token.new('onedrive_token')
      @file_list    = FileList.new('onedrive_list')
      @file_id      = nil
      @root_id      = ROOT_ID
      @storage_name = STORAGE_NAME
    end

    def load_token(token_file = 'onedrive_token')
      @token = Token.load_token(token_file)
    end

    def refresh_token
      raise TokenClassException unless @token.is_a?(Token)
      info = request_refresh_token
      raise NoDataException if info.nil?
      @token.set_attributes(info)
      @token.write_token
    rescue => e
      handle_exception(e)
    end

   def login
      url  = login_browser
      info = request_get_token(url)
      raise NoDataException if info.nil?
      reset_token(info)
      true
    rescue => e
      handle_exception(e)
    end

    private

    def request_get_token(url)
      query  = URI.parse(url).query
      raise AccessCodeNotIncludeException if query.nil?
      params = CGI.parse(query)
      raise AccessCodeNotIncludeException unless params.key?('code')
      code = params['code'][0]
      api  = OneDriveApi.new(@token.access_token)
      api.request_get_token(
        code,
        @config.client_id,
        @config.client_secret,
        @config.redirect_url
      )
    end

    def request_refresh_token
      api = OneDriveApi.new(@token.access_token)
      api.request_refresh_token(
        @token.refresh_token,
        @config.client_id,
        @config.client_secret,
        @config.redirect_url
      )
    end

    def request_user
      api = OneDriveApi.new(@token.access_token)
      api.request_user
    end

    def request_dir
      file_id = @parent_id || @file_id || ROOT_ID
      api     = OneDriveApi.new(@token.access_token)
      api.request_dir(file_id)
    end

    def request_file
      api = OneDriveApi.new(@token.access_token)
      api.request_file(@file_id)
    end

    def request_download
      api     = OneDriveApi.new(@token.access_token)
      contens = api.request_download(@file_id)
      open("#{@file_name}", 'wb') { |file| file << contens }
    end

    def request_upload(file_path)
      api = OneDriveApi.new(@token.access_token)
      api.request_upload(file_path, @parent_id)
    end

    def request_delete
      api = OneDriveApi.new(@token.access_token)
      api.request_delete(@file_id)
    end

    def request_mkdir
      parent_id = @parent_id || ROOT_ID
      api       = OneDriveApi.new(@token.access_token)
      api.request_mkdir(@mkdir_name, parent_id)
    end

    def pull_files
      dir = pick_cloud_info('request_dir', 'data')
      return {} if dir.nil? || !dir.is_a?(Array) || dir.count == 0
      items = {}
      dir.each do |item|
        type = get_type_from_id(item['id'])
        items[item['name']] = {'id' => item['id'], 'type' => type}
      end
      items
    end

    def format_property(info)
      items = {}
      info.each do |key, val|
        if key =~ TIME_PROPERTY_PAT
          items[key] = DateTime.parse(info[key]).strftime('%Y-%m-%d %H:%M:%S')
        else
          items[key] = info[key]
        end
      end
      items
    end

    def get_type_from_id(file_id)
      file_id.split('.')[0]
    end

    def login_browser
      auth_url = OneDriveApi.make_auth_url(@config.client_id, @config.redirect_url)
      browser  = Watir::Browser.new :phantomjs
      # input account
      browser.goto(auth_url)
      browser.wait
      browser.text_field(:name, LOGIN_COMPONENTS['account_text_name']).set @account.login_account
      browser.text_field(:name, LOGIN_COMPONENTS['password_text_name']).set @account.login_password
      browser.button(:id, LOGIN_COMPONENTS['signin_button_id']).click
      browser.wait
      # allow access
      browser.button(:id, LOGIN_COMPONENTS['accept_button_id']).click
      browser.wait
      # get redirect url
      url = browser.url
      browser.close
      url
    rescue => e
      handle_exception(e)
    end
  end
end
