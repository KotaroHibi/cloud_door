class Token
  attr_accessor :token_file, :token_type, :expires_in, :scope, :access_token, :refresh_token, :user_id

  TOKEN_FILE = 'onedrive_token'

  TOKEN_ITEMS = [
    'token_type',
    'expires_in',
    'scope',
    'access_token',
    'refresh_token',
    'user_id',
  ]

  def initialize
    @token_file = TOKEN_FILE
  end

  def set_attributes(attributes)
    TOKEN_ITEMS.each do |item|
      instance_variable_set("@#{item}", attributes[item]) if attributes.has_key?(item)
    end
  end

  def write_token
    begin
      marshal = Marshal.dump(self)
      open(@token_file, 'wb') { |file| file << marshal }
      true
    rescue
      false
    end
  end

  def self.load_token(token_file=TOKEN_FILE)
    begin
      return nil unless File.exists?(token_file)
      marshal = File.open(token_file).read
      token = Marshal.load(marshal)
      return nil unless token.is_a?(Token)
      token
    rescue
      nil
    end
  end
end
