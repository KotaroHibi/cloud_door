module CloudDoor
  class Token
    attr_accessor :token_file, :token_type, :expires_in, :scope, :access_token,
                  :refresh_token, :user_id

    TOKEN_DIR = './data/'

    TOKEN_ITEMS = [
      'token_type',
      'expires_in',
      'scope',
      'access_token',
      'refresh_token',
      'user_id'
    ]

    def initialize(token_file)
      @token_file = TOKEN_DIR + token_file
    end

    def set_attributes(attributes)
      TOKEN_ITEMS.each do |item|
        instance_variable_set("@#{item}", attributes[item]) if attributes.key?(item)
      end
    end

    def write_token
      marshal = Marshal.dump(self)
      open(@token_file, 'wb') { |file| file << marshal }
      true
    rescue
      false
    end

    def self.load_token(token_file)
      token_file = TOKEN_DIR + token_file
      return nil unless File.exist?(token_file)
      marshal = File.open(token_file).read
      token = Marshal.load(marshal)
      return nil unless token.is_a?(Token)
      token
    rescue
      nil
    end
  end
end
