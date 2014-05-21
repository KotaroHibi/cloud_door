require 'yaml'
require 'logger'
require 'open-uri'
require 'rest_client'
require 'watir-webdriver'
require 'cloud_door/version'
require 'cloud_door/account'
require 'cloud_door/cloud_config'
require 'cloud_door/token'

module CloudDoor
  class OneDrive
    attr_accessor :token, :file_id
    attr_reader :config, :account

    # domain for auth
    AUTH_BASE = "https://login.live.com/"
    # URL for auth
    AUTH_FORMAT = AUTH_BASE + "oauth20_authorize.srf?client_id=%s&scope=%s&response_type=code&redirect_uri=%s"
    # URL for get token
    TOKEN_URL = AUTH_BASE + 'oauth20_token.srf'
    # domain for action
    ACTION_BASE = "https://apis.live.net/v5.0/"
    # URL for get user info
    USER_FORMAT =  ACTION_BASE + "me?access_token=%s"
    # URL for get directory
    DIR_FORMAT = ACTION_BASE + "%s/files?access_token=%s"
    # URL for get root directory
    ROOT_FORMAT = ACTION_BASE + "me/skydrive/files?access_token=%s"
    # URL for get file info
    FILE_FORMAT = ACTION_BASE + "%s?access_token=%s"
    # URL for download file
    DOWNLOAD_FORMAT = ACTION_BASE + "%s/content?suppress_redirects=true&access_token=%s"
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

    def initialize
      @config  = CloudConfig.new('onedrive')
      @account = Account.new('onedrive')
      @token   = Token.new
      @file_id = nil
    end

    def get_auth_url
      AUTH_FORMAT % [@config.client_id, UPDATE_SCOPE, @config.redirect_url]
    end

    def set_token(token_file='')
      @token = Token.load_token(token_file)
    end

    def reset_token(url)
      info = request_get_token(url)
      return false if info.nil?
      return false unless @token.is_a?(Token)
      @token.set_attributes(info)
      @token.write_token
    end

    def refresh_token
      info = request_refresh_token
      return false if info.nil?
      return false unless @token.is_a?(Token)
      @token.set_attributes(info)
      @token.write_token
    end

    def get_onedrive_info(target, key)
      if ['user', 'dir', 'file'].include?(target)
        info = send("request_#{target}".to_sym)
      else
        return nil
      end
      return nil if (info.nil? || !info.is_a?(Hash) || !info.has_key?(key))
      info[key]
    end

    def show_dir
      dir = get_onedrive_info('dir', 'data')
      return [] if (dir.nil? || !dir.is_a?(Array) || dir.count == 0)
      items = []
      dir.each do |item|
        items << "#{item['name']} [#{item['id']}]"
      end
      items
    end

    def download_file
      begin
        key  = 'location'
        info = request_download()
        return false if (info.nil? || !info.is_a?(Hash) || !info.has_key?(key))
        file_url  = info[key]
        file_name = get_onedrive_info('file', 'name')
        return false if file_name.nil?
        open("#{file_name}", 'wb') do |file|
          file << open(file_url).read
        end
        File.exist?(file_name)
      rescue
        false
      end
    end

    def login_browser
      begin
        browser = Watir::Browser.new :phantomjs
        browser.goto(get_auth_url)
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
      rescue
        nil
      end
    end

    private
    def send_request(method, url, body='', header='')
      logger = Logger.new(LOG_FILE)
      begin
        if method == :post
          res = RestClient.post(url, body, header) do |response, request, result|
            log = "request:\n#{request.inspect}\n"
            log << "result:\n#{result.inspect}\n"
            log << "response:\n#{JSON.parse(response.body).inspect}\n"
            logger.info(log)
            response
          end
        else
          res = RestClient.get(url) do |response, request, result|
            log = "request:\n#{request.inspect}\n"
            log << "result:\n#{result.inspect}\n"
            log << "response:\n#{JSON.parse(response.body).inspect}\n"
            logger.info(log)
            response
          end
        end
        JSON.parse(res.body)
      rescue
        nil
      end
    end

    def request_get_token(url)
      begin
        params = CGI.parse(URI.parse(url).query)
        return nil if !params.has_key?('code')
        code = params['code'][0]
        post_body = {
          :client_id     => @config.client_id,
          :client_secret => @config.client_secret,
          :redirect_uri  => @config.redirect_url,
          :code          => code,
          :grant_type    => 'authorization_code'
        }
        header = {:content_type => 'application/x-www-form-urlencoded'}
        send_request(:post, TOKEN_URL, post_body, header)
      rescue
        nil
      end
    end

    def request_refresh_token
      post_body = {
        :client_id     => @config.client_id,
        :client_secret => @config.client_secret,
        :redirect_uri  => @config.redirect_url,
        :grant_type    => 'refresh_token',
        :refresh_token => @token.refresh_token
      }
      header = {:content_type => 'application/x-www-form-urlencoded'}
      send_request(:post, TOKEN_URL, post_body, header)
    end

    def request_user
      url = USER_FORMAT % @token.access_token
      send_request(:get, url)
    end

    def request_dir
      if (@file_id.nil? || @file_id.empty?)
        url = ROOT_FORMAT % @token.access_token
      else
        url = DIR_FORMAT % [@file_id, @token.access_token]
      end
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
  end
end
