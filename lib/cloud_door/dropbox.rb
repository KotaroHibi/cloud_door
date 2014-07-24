require 'dropbox_sdk'
require 'cloud_door/cloud_storage'

module CloudDoor
  class Dropbox < CloudStorage
    attr_accessor :token, :file_list, :file_id, :file_name,
                  :up_file_name, :mkdir_name, :parent_id
    attr_reader :config, :account

    # dropbox login site components
    LOGIN_COMPONENTS = {
      'account_text_name'   => 'login_email',
      'password_text_name'  => 'login_password',
      'signin_button_class' => 'login-button',
      'accept_button_name'  => 'allow_access',
      'auth_code_id'        => 'auth-code'
    }

    TIME_PROPERTIES = %w(client_mtime modified)
    CONTENTS_KEY    = 'contents'
    ROOT_ID         = '/'
    STORAGE_NAME    = 'Dropbox'

    def initialize(session_id = nil)
      @config       = Config.new('dropbox')
      @account      = Account.new('dropbox', @config.data_path)
      @token        = Token.new('dropbox_token', @config.data_path, session_id)
      @file_list    = FileList.new('dropbox_list', @config.data_path, session_id)
      @file_id      = nil
      @root_id      = ROOT_ID
      @storage_name = STORAGE_NAME
      @session_id   = session_id
      @client       = nil
    end

    def load_token
      token_file = File.basename(@token.token_file)
      @token     = Token.load_token(token_file, @config.data_path, @session_id)
      @client    = DropboxClient.new(@token.access_token)
      @token
    end

    def login(login_account, login_password)
      @account.login_account  = login_account
      @account.login_password = login_password
      flow = DropboxOAuth2FlowNoRedirect.new(@config.client_id, @config.client_secret)
      code = login_browser(flow.start())
      access_token, user_id = flow.finish(code)
      raise NoDataException if access_token.nil?
      @session_id = reset_token({'access_token' => access_token})
      @client = DropboxClient.new(access_token)
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

    private

    def request_user
      info = @client.account_info()
      raise NoDataException if info.nil? || info.empty?
      info
    end

    def request_dir
      file_id = @parent_id || @file_id || ROOT_ID
      @client.metadata(file_id)
    end

    def request_file
      @client.metadata(@file_id)
    end

    def request_download
      contents, metadata = @client.get_file_and_metadata(@file_id)
      open(@file_name, 'w') {|f| f.puts contents }
      metadata
    end

    def request_upload(file_path)
      if @parent_id == ROOT_ID
        to_path = @parent_id + file_path
      else
        to_path = "#{@parent_id}/#{file_path}"
      end
      response = @client.put_file(to_path, open(file_path))
      raise UploadFailedException if response.nil? || response.empty?
      response
    end

    def request_delete
      response = @client.file_delete(@file_id)
      raise DeleteFailedException if response.nil? || response.empty?
      response
    end

    def request_mkdir
      if @parent_id == ROOT_ID
        path = @parent_id + @mkdir_name
      else
        path = "#{@parent_id}/#{@mkdir_name}"
      end
      response = @client.file_create_folder(path)
      raise MkdirFailedException if response.nil? || response.empty?
      response
    end

    def pull_files
      dir = pick_cloud_info('request_dir', 'contents')
      return {} if dir.nil? || !dir.is_a?(Array) || dir.count == 0
      items = {}
      dir.each do |item|
        path, name = File.split(item['path'])
        type = item['is_dir'] ? 'folder' : 'file'
        items[name] = {'id' => item['path'], 'type' => type}
      end
      items
    end

    def format_property(info)
      path, name = File.split(info['path'])
      items = {}
      items['name'] = name
      info.each do |key, val|
        if TIME_PROPERTIES.include?(key)
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
      browser.text_field(:name, LOGIN_COMPONENTS['account_text_name']).set @account.login_account
      browser.text_field(:name, LOGIN_COMPONENTS['password_text_name']).set @account.login_password
      browser.button(:class, LOGIN_COMPONENTS['signin_button_class']).click
      browser.button(:name => LOGIN_COMPONENTS['accept_button_name']).wait_until_present
      # allow access
      browser.button(:name, LOGIN_COMPONENTS['accept_button_name']).click
      browser.wait
      # get code
      code = browser.div(:id, LOGIN_COMPONENTS['auth_code_id']).text
      browser.close
      code
    rescue => e
      handle_exception(e)
    end
  end
end
