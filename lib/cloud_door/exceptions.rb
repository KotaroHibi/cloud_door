module CloudDoor
  class FileNameEmptyException < StandardError
    def message
      'filename is not set.'
    end

    def to_s
      message
    end
  end

  class DirectoryNameEmptyException < StandardError
    def message
      'directory name is not set.'
    end

    def to_s
      message
    end
  end

  class SetIDException < StandardError
    def message
      'not found input file name.'
    end

    def to_s
      message
    end
  end

  class NotFileException < StandardError
    def message
      'target is not file.'
    end

    def to_s
      message
    end
  end

  class NotDirectoryException < StandardError
    def message
      'target is not directory.'
    end

    def to_s
      message
    end
  end

  class NoDataException < StandardError
    def message
      'not found request data.'
    end

    def to_s
      message
    end
  end

  class TokenClassException < StandardError
    def message
      'token is not Token Class.'
    end

    def to_s
      message
    end
  end

  class FileNotExistsException < StandardError
  end

  class RequestMethodNotFoundException < StandardError
  end

  class RequestPropertyNotFoundException < StandardError
  end

  class AccessCodeNotIncludeException < StandardError
    def message
      'access code not include in redirect url.'
    end

    def to_s
      message
    end
  end

  class UnauthorizedException < StandardError
    def message
      'authentication failed.'
    end

    def to_s
      message
    end
  end

  class HttpConnectionException < StandardError
    def message
      'access to storage failed.'
    end

    def to_s
      message
    end
  end
end
