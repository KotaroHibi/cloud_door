module CloudDoor
  class Token
    attr_accessor :token_file, :token_type, :expires_in, :scope, :access_token,
                  :refresh_token, :user_id, :token_name, :credentials
    attr_reader :data_path

    TOKEN_ITEMS = [
      'token_type',
      'expires_in',
      'scope',
      'access_token',
      'refresh_token',
      'user_id',
      'credentials'
    ]

    def initialize(token_name, data_path, id = nil)
      @token_name = token_name
      @data_path  = data_path
      if id.nil?
        @token_file = @data_path + @token_name
      else
        token_dir = @data_path + "#{id}"
        unless File.exists?(token_dir)
          Dir.mkdir(token_dir)
        end
        @token_file = "#{token_dir}/#{@token_name}"
      end
    end

    def set_locate(id)
      token_dir = @data_path + "#{id}"
      unless File.exists?(token_dir)
        Dir.mkdir(token_dir)
      end
      @token_file = "#{token_dir}/#{@token_name}"
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

    def self.load_token(token_name, data_path, id = nil)
      if id.nil?
        token_file = data_path + token_name
      else
        token_file = data_path + "#{id}/#{token_name}"
      end
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
