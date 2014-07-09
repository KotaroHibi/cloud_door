require 'logger'
require 'open-uri'
require 'rest_client'

module CloudDoor
  class OneDriveApi
    attr_accessor :access_token

    # domain for auth
    AUTH_BASE = 'https://login.live.com/'
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
    # log_file
    LOG_FILE = './log/request.log'

    def initialize(access_token)
      @access_token = access_token
    end

    def request_get_token(code, client_id, client_secret, redirect_url)
      post_body = {
        client_id:     client_id,
        client_secret: client_secret,
        redirect_uri:  redirect_url,
        code:          code,
        grant_type:    'authorization_code'
      }
      header = {content_type: 'application/x-www-form-urlencoded'}
      send_request(:post, TOKEN_URL, post_body, header)
    end

    def request_refresh_token(refresh_token, client_id, client_secret, redirect_url)
      post_body = {
        client_id:     client_id,
        client_secret: client_secret,
        redirect_uri:  redirect_url,
        grant_type:    'refresh_token',
        refresh_token: refresh_token
      }
      header = {content_type: 'application/x-www-form-urlencoded'}
      send_request(:post, TOKEN_URL, post_body, header)
    end

    def request_user
      url = USER_FORMAT % @access_token
      send_request(:get, url)
    end

    def request_dir(file_id)
      url = DIR_FORMAT % [file_id, @access_token]
      send_request(:get, url)
    end

    def request_file(file_id)
      url = FILE_FORMAT % [file_id, @access_token]
      send_request(:get, url)
    end

    def request_download(file_id)
      url  = DOWNLOAD_FORMAT % [file_id, @access_token]
      info = send_request(:get, url)
      key  = 'location'
      raise NoDataException if info.nil? || !info.is_a?(Hash) || !info.key?(key)
      file_url = info[key]
      open(file_url).read
    end

    def request_upload(file_path, parent_id)
      url = UPLOAD_FORMAT % [parent_id, @access_token]
      send_request(:post_file, url, File.new(file_path, 'rb'))
    end

    def request_delete(file_id)
      url = DELETE_FORMAT % [file_id, @access_token]
      send_request(:delete, url)
    end

    def request_mkdir(name, parent_id)
      url = MKDIR_FORMAT % parent_id
      body = JSON('name' => name)
      header = {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type'  => 'application/json'
      }
      send_request(:post, url, body, header)
    end

    class << self
      def make_auth_url(client_id, redirect_url)
        AUTH_FORMAT % [client_id, UPDATE_SCOPE, redirect_url]
      end
    end

    private

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
      # raise NoDataException if res.body.nil? || res.body.empty?
      return if res.body.nil? || res.body.empty?
      JSON.parse(res.body)
    rescue => e
      if e.is_a?(RestClient::Unauthorized)
        raise UnauthorizedException
      elsif e.class.to_s.include?('RestClient')
        raise HttpConnectionException
      else
        raise
      end
    end

    def request_log(response, request, result)
      logger = Logger.new(LOG_FILE)
      log = "request:\n#{request.args.inspect}\n"
      log << "result:\n#{result.inspect}\n"
      log << "response:\n#{JSON.parse(response.body).inspect}\n"
      logger.info(log)
    end
  end
end
