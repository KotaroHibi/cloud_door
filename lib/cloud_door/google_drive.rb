require 'cloud_door/cloud_storage'
require 'cloud_door/google_drive_bridge'

module CloudDoor
  class GoogleDrive < CloudStorage
    attr_accessor :token, :file_list, :file_id, :file_name,
                  :up_file_name, :mkdir_name, :parent_id
    attr_reader :config, :account

    # google drive login site components
    LOGIN_COMPONENTS = {
      'account_text_id'  => 'Email',
      'password_text_id' => 'Passwd',
      'signin_button_id' => 'signIn',
      'accept_button_id' => 'submit_approve_access',
      'auth_code_id'     => 'code'
    }

    TIME_PROPERTY_PAT = /Date$/
    CONTENTS_KEY    = 'contents'
    ROOT_ID         = '/'
    STORAGE_NAME    = 'Google Drive'
    OAUTH_SCOPE     = 'https://www.googleapis.com/auth/drive'

    def initialize(session_id = nil)
      @config       = Config.new('googledrive')
      @account      = Account.new('googledrive', @config.data_path)
      @token        = Token.new('googledrive_token', @config.data_path, session_id)
      @file_list    = FileList.new('googledrive_list', @config.data_path, session_id)
      @file_id      = nil
      @root_id      = ROOT_ID
      @storage_name = STORAGE_NAME
      @session_id   = session_id
      @client       = nil
    end

    def load_token
      token_file = File.basename(@token.token_file)
      @token     = Token.load_token(token_file, @config.data_path, @session_id)
      @client    = GoogleDriveBridge.new(Marshal.load(@token.credentials))
      @root_id   = request_root_id
      @token
    end

   def login(login_account, login_password)
      @account.login_account  = login_account
      @account.login_password = login_password
      client = create_login_client
      code   = login_browser(client.authorization.authorization_uri.to_s)
      client.authorization.code = code
      client.authorization.fetch_access_token!
      credentials = client.authorization
      raise NoDataException if credentials.nil?
      @session_id = reset_token({'credentials' => Marshal.dump(credentials)})
      @client     = GoogleDriveBridge.new(credentials)
      @root_id    = request_root_id
      items = pull_files
      @file_list.delete_file
      @file_list.write_file_list(items)
      if @config.session_use?
        @session_id
      else
        true
      end
    rescue => e
      handle_exception(e)
    end

    def create_login_client
      client = Google::APIClient.new
      client.authorization.client_id = @config.client_id
      client.authorization.client_secret = @config.client_secret
      client.authorization.scope = OAUTH_SCOPE
      client.authorization.redirect_uri = @config.redirect_url
      client
    end

    private

    def request_user
      @client.request_user
    end

    def request_root_id
      @client.request_root_id
    end

    def request_dir
      file_id = @parent_id || @file_id || @root_id
      @client.request_dir(file_id)
    end

    def request_file
      @client.request_file(@file_id)
    end

    def request_download
      body = @client.request_download(@file_id)
      if body
        open(@file_name, 'w') {|f| f.puts body }
      end
    end

    def request_upload(file_path)
      @client.request_upload(file_path, @parent_id)
    end

    def request_delete
      @client.request_delete(@file_id)
      true
    rescue => e
      false
    end

    def request_mkdir
      @client.request_mkdir(@mkdir_name, @parent_id)
    end

    def pull_files
      dir = request_dir
      return {} if dir.nil? || !dir.is_a?(Array) || dir.count == 0
      items = {}
      dir.each do |item|
        id   = item['id']
        name = item['title']
        type = (item['mimeType'] == 'application/vnd.google-apps.folder') ? 'folder' : 'file'
        items[name] = {'id' => id, 'type' => type}
      end
      items
    end

    def format_property(info)
      items = {}
      items['name'] = info['title']
      info.each do |key, val|
        if key =~ TIME_PROPERTY_PAT
          items[key] = DateTime.parse(val).strftime('%Y-%m-%d %H:%M:%S')
        elsif key == CONTENTS_KEY
          items['count'] = val.count
        else
          items[key] = val
        end
      end
      items
    end

    def login_browser(auth_url)
      browser = Watir::Browser.new :phantomjs

      # input account
      browser.goto(auth_url)
      browser.wait
      browser.text_field(:id, LOGIN_COMPONENTS['account_text_id']).set @account.login_account
      browser.text_field(:id, LOGIN_COMPONENTS['password_text_id']).set @account.login_password
      browser.button(:id, LOGIN_COMPONENTS['signin_button_id']).click
      # allow access
      Watir::Wait.until { browser.button(:id => LOGIN_COMPONENTS['accept_button_id']).enabled? }
      browser.button(:id, LOGIN_COMPONENTS['accept_button_id']).click
      browser.wait
      # get code
      code = browser.text_field(:id, LOGIN_COMPONENTS['auth_code_id']).value
      browser.close
      code
    rescue => e
      handle_exception(e)
    end
  end

end
