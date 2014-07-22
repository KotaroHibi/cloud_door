require 'google/api_client'
require 'yaml'
require 'mimetype_fu'
require 'cloud_door/cloud_storage'

module CloudDoor
  class GoogleDriveBridge
    def initialize(credentials)
      client = Google::APIClient.new(application_name: 'cloud_door')
      client.authorization = credentials
      drive  = client.discovered_api('drive', 'v2')
      @gclient = client
      @gdrive  = drive
    end

    def request_user
      result = send_request('@gdrive.about.get')
      result.data.user
    end

    def request_root_id
      result = send_request('@gdrive.about.get')
      result.data.root_folder_id
    end

    def request_dir(file_id)
      dir_files  = Array.new
      page_token = nil
      begin
        parameters = {}
        parameters['q'] = "'#{file_id}' in parents"
        if page_token.to_s != ''
          parameters['pageToken'] = page_token
        end
        api_result = send_request('@gdrive.files.list', parameters: parameters)
        files = api_result.data
        dir_files.concat(files.items)
        page_token = files.next_page_token
      end while page_token.to_s != ''
      dir_files
    end

    def request_file(file_id)
      result = send_request('@gdrive.files.get', {parameters: {'fileId' => file_id}})
      result.data.to_hash
    end

    def request_download(file_id)
      result = @gclient.execute(
        api_method: @gdrive.files.get,
        parameters: {'fileId' => file_id}
      )
      file = result.data
      if file.download_url
        result = @gclient.execute(:uri => file.download_url)
        if result.status == 200
          result.body
        elsif result.status == 401
          raise UnauthorizedException
        else
          raise HttpConnectionException
        end
      end
    end

    def request_upload(file_path, parent_id)
      mime      = File.mime_type?(File.open(file_path))
      mime_type = mime[0, mime.index(';')]
      file = @gdrive.files.insert.request_schema.new({
        'title' => file_path
      })
      if parent_id
        file.parents = [{'id' => parent_id}]
      end
      media = Google::APIClient::UploadIO.new(file_path, mime_type)
      result = @gclient.execute(
        :api_method  => @gdrive.files.insert,
        :body_object => file,
        :media       => media,
        :parameters  => {
          'uploadType' => 'multipart',
          'alt'        => 'json'
        }
      )
      if result.status == 200
        result
      elsif result.status == 401
        raise UnauthorizedException
      else
        raise HttpConnectionException
      end
    end

    def request_delete(file_id)
      send_request('@gdrive.files.delete', {parameters: {'fileId' => file_id}})
      true
    rescue => e
      false
    end

    def request_mkdir(name, parent_id)
      file = @gdrive.files.insert.request_schema.new({
        'title'    => name,
        'mimeType' => 'application/vnd.google-apps.folder',
        'parents'  => [{'id' => parent_id}]
      })
      result = @gclient.execute(
        :api_method => @gdrive.files.insert,
        :body_object => file
      )
      if result.status == 200
        true
      elsif result.status == 401
        raise UnauthorizedException
      else
        raise HttpConnectionException
      end
    end

    private

    def send_request(api_method, parameters = {})
      requests = {api_method: eval(api_method)}
      requests.merge!(parameters)
      result = @gclient.execute(requests)
      if result.status == 200
        result
      elsif result.status == 401
        raise UnauthorizedException
      else
        raise HttpConnectionException
      end
    end

  end

end
