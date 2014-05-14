require "cloud_door/version"
require 'yaml'
require 'RestClient'
require 'open-uri'

module CloudDoor
  class OneDrive
    attr_accessor :client_id, :client_secret, :redirect_url, :token_file, :token

    # URL for auth
    AUTH_FORMAT = "https://login.live.com/oauth20_authorize.srf?client_id=%s&scope=%s&response_type=code&redirect_uri=%s"
    # URL for get user info
    USER_FORMAT =  "https://apis.live.net/v5.0/me?access_token=%s"
    # URL for get directory
    DIR_FORMAT = "https://apis.live.net/v5.0/%s/files?access_token=%s"
    # URL for get root directory
    ROOT_FORMAT = "https://apis.live.net/v5.0/me/skydrive/files?access_token=%s"
    # URL for get file info
    FILE_FORMAT = "https://apis.live.net/v5.0/%s?access_token=%s"
    # URL for download file
    DOWNLOAD_FORMAT = "https://apis.live.net/v5.0/%s/content?suppress_redirects=true&access_token=%s"
    # URL for get token
    TOKEN_URL = 'https://login.live.com/oauth20_token.srf'
    # update scope
    UPDATE_SCOPE = 'wl.skydrive_update'

    def initialize
      load_yaml
    end

    def load_yaml
      config = YAML.load_file('cloud.yml')
      @client_id     = config['onedrive']['client_id']
      @client_secret = config['onedrive']['client_secret']
      @redirect_url  = config['onedrive']['redirect_url']
      @token_file    = config['onedrive']['token_file']
    end

    def update_yaml(onedrive_params)
      config = YAML.load_file('cloud.yml')
      config['onedrive']['client_id']     = onedrive_params['client_id']
      config['onedrive']['client_secret'] = onedrive_params['client_secret']
      config['onedrive']['redirect_url']  = onedrive_params['redirect_url']
      open('cloud.yml', 'w') { |file| YAML.dump(config, file) }
    end

    def get_auth_url
      AUTH_FORMAT % [@client_id, UPDATE_SCOPE, @redirect_url]
    end

    def set_token()
      @token = File.open(@token_file).read
    end

    def reset_token(url)
      info = request_token(url)
      return false if info.nil?
      token = info['access_token']
      open(@token_file, 'wb') { |file| file << token }
      true
    end

    def get_onedrive_info(target, key, id='')
      if ['user', 'dir', 'file'].include?(target)
        info = send("request_#{target}".to_sym, id)
      else
        return nil
      end
      return nil if (info.nil? || !info.is_a?(Hash) || !info.has_key?(key))
      info[key]
    end

    def show_dir(id='')
      dir = get_onedrive_info('dir', 'data', id)
      return [] if (dir.nil? || !dir.is_a?(Array) || dir.count == 0)
      items = []
      dir.each do |item|
        items << "#{item['name']} [#{item['id']}]"
      end
      items
    end

    def download_file(id)
      key  = 'location'
      info = request_download(id)
      return false if (info.nil? || !info.is_a?(Hash) || !info.has_key?(key))
      file_url  = info[key]
      file_name = get_onedrive_info('file', 'name', id)
      return false if file_name.nil?
      open("#{file_name}", 'wb') do |file|
        file << open(file_url).read
      end
      File.exist?(file_name)
    end

    private
    def send_request(method, url, body='', header='')
      begin
        if method == :post
          res = RestClient.post(url, body, header)
        else
          res = RestClient.get(url)
        end
        JSON.parse(res.body)
      rescue
        nil
      end
    end

    def request_token(url)
      begin
        params = CGI.parse(URI.parse(url).query)
        raise 'code nothing' if !params.has_key?('code')
        code = params['code'][0]
        post_body = {
          :client_id     => @client_id,
          :client_secret => @client_secret,
          :redirect_uri  => @redirect_url,
          :code          => code,
          :grant_type    => 'authorization_code'
        }
        header = {:content_type => 'application/x-www-form-urlencoded'}
        send_request(:post, TOKEN_URL, post_body, header)
      rescue
        nil
      end
    end

    def request_user(id='')
      url = USER_FORMAT % @token
      send_request(:get, url)
    end

    def request_dir(id='')
      if (id.nil? || id.empty?)
        url = ROOT_FORMAT % @token
      else
        url = DIR_FORMAT % [id, @token]
      end
      send_request(:get, url)
    end

    def request_file(id)
      url = FILE_FORMAT % [id, @token]
      send_request(:get, url)
    end

    def request_download(id)
      url = DOWNLOAD_FORMAT % [id, @token]
      send_request(:get, url)
    end
  end
end
