require 'spec_helper'

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end

def create_onedrive(file_id=nil)
  storage = CloudDoor::OneDrive.new
  storage.file_id              = file_id
  storage.token.token_file     = '.test'
  storage.token.refresh_token  = 'refresh'
  storage.config.client_id     = '1234'
  storage.config.client_secret = 'abcd'
  storage.config.redirect_url  = 'onedrive'
  storage.file_list.list_file  = '.testlist'
  storage
end

describe 'OneDrive' do
  describe 'get_auth_url' do
    let(:storage) { create_onedrive }
    let(:url) {
      CloudDoor::OneDrive::AUTH_FORMAT %
        [storage.config.client_id, CloudDoor::OneDrive::UPDATE_SCOPE, storage.config.redirect_url]
    }
    it { expect(storage.get_auth_url).to eq url }
  end

  describe 'set_token' do
    let(:token) { Fabricate.build(:token) }
    let(:storage) { create_onedrive }
    let(:token_file) { storage.token.token_file }
    before (:each) do
      open(token_file, 'wb') { |file| file << Marshal.dump(token) }
    end
    it {
      token = storage.set_token(storage.token.token_file)
      expect(token.is_a?(Token)).to be_true
    }
    after (:each) do
      File.delete(token_file) if File.exists?(token_file)
    end
  end

  describe 'reset_token' do
    let(:storage) { create_onedrive }
    let(:token_file) { storage.token.token_file }
    let(:code) { '5678' }
    let(:url) { CloudDoor::OneDrive::TOKEN_URL + "?code=#{code}" }
    context 'success' do
      before (:each) do
        body = JSON({'access_token' => 'token'})
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.reset_token(url)).to be_true }
      it { expect(File.exists?(token_file)).to be_true }
      it { expect(Marshal.load(File.open(token_file).read).access_token).to eq 'token' }
      after (:all) do
        File.delete(token_file) if File.exists?(token_file)
      end
    end
    context 'fail' do
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 404, :body => {}, :headers => {})
      end
      it { expect(storage.reset_token(url)).to be_false }
      it { expect(File.exists?(token_file)).to be_false }
    end
  end

  describe 'refresh_token' do
    let(:storage) { create_onedrive }
    let(:token_file) { storage.token.token_file }
    context 'success' do
      before (:each) do
        body = JSON({'access_token' => 'token'})
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.refresh_token).to be_true }
      it { expect(File.exists?(token_file)).to be_true }
      it { expect(Marshal.load(File.open(token_file).read).access_token).to eq 'token' }
      after (:all) do
        File.delete(token_file) if File.exists?(token_file)
      end
    end
    context 'fail' do
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 404, :body => {}, :headers => {})
      end
      it { expect(storage.refresh_token).to be_false }
      it { expect(File.exists?(token_file)).to be_false }
    end
  end

  describe 'get_onedrive_info' do
    context 'user' do
      let(:storage) { create_onedrive }
      let(:access_token) { storage.token.access_token }
      let(:url) { CloudDoor::OneDrive::USER_FORMAT % access_token }
      before (:each) do
        body = JSON({'name' => 'onedrive'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.get_onedrive_info('user', 'name')).to eq 'onedrive' }
    end
    context 'dir' do
      context 'root' do
        let(:storage) { create_onedrive }
        let(:access_token) { storage.token.access_token }
        let(:url) { CloudDoor::OneDrive::ROOT_FORMAT % access_token }
        before (:each) do
          body = JSON({'data' => ['onedrive']})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.get_onedrive_info('dir', 'data')).to eq ['onedrive'] }
      end
      context 'dir' do
        let(:storage) { create_onedrive('1234') }
        let(:access_token) { storage.token.access_token }
        let(:url) { CloudDoor::OneDrive::DIR_FORMAT % [storage.file_id, access_token] }
        before (:each) do
          body = JSON({'data' => ['onedrive']})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.get_onedrive_info('dir', 'data')).to eq ['onedrive'] }
      end
    end
    context 'file' do
      let(:storage) { create_onedrive('1234') }
      let(:access_token) { storage.token.access_token }
      let(:url) { CloudDoor::OneDrive::FILE_FORMAT % [storage.file_id, access_token] }
      before (:each) do
        body = JSON({'name' => 'onedrive'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.get_onedrive_info('file', 'name')).to eq 'onedrive' }
    end
    context 'fail' do
      let(:storage) { create_onedrive }
      let(:access_token) { storage.token.access_token }
      let(:url) { CloudDoor::OneDrive::USER_FORMAT % access_token }
      context 'target not exists' do
        before (:each) do
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.get_onedrive_info('member', 'name')).to be_nil }
      end
      context 'key not exists' do
        before (:each) do
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.get_onedrive_info('user', 'firstname')).to be_nil }
      end
      context 'request fail' do
        before (:each) do
          WebMock.stub_request(:get, url).
            to_return(:status => 404, :body => {}, :headers => {})
        end
        it { expect(storage.get_onedrive_info('user', 'name')).to be_nil }
      end
    end
  end

  describe 'show_files' do
    let(:storage) { create_onedrive }
    let(:url) { CloudDoor::OneDrive::ROOT_FORMAT % storage.token.access_token }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      before (:each) do
        body = JSON({'data' => [
          {'id' => 'file.1234', 'name' => 'onedrive'},
          {'id' => 'file.5678', 'name' => 'skydrive'}
        ]})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.show_files).to eq({'onedrive' => 'file.1234', 'skydrive' => 'file.5678'}) }
    end
    context 'fail' do
      context 'data not exists' do
        before (:each) do
          body = JSON({'data' => []})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.show_files).to eq({}) }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { expect(storage.show_files).to eq({}) }
      end
      context 'not directory' do
        before (:each) do
          list = [{'items' => {'test' => 'file.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
        end
        it { expect(storage.show_files).to eq({}) }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'show_current_dir' do
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      context 'top' do
        it { expect(storage.show_current_dir).to eq('/top') }
      end
      context 'layered' do
        before (:each) do
          list = [
            {'name' => 'top'},
            {'name' => 'layer1'},
            {'name' => 'layer2'},
          ]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        end
        it { expect(storage.show_current_dir).to eq('/top/layer1/layer2') }
        after (:each) do
          File.delete(list_file) if File.exists?(list_file)
        end
      end
    end
    context 'fail' do
      context 'load error' do
        before (:each) do
          list = {'name' => 'layer1'}
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        end
        it { expect(storage.show_current_dir).to be_false }
        after (:each) do
          File.delete(list_file) if File.exists?(list_file)
        end
      end
    end
  end

  describe 'delete_file' do
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::DELETE_FORMAT % [ 'file.1234', access_token ] }
    context 'success' do
      before (:each) do
        list = [{'items' => {'test' => 'file.1234'}}]
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        storage.file_name = 'test'
        WebMock.stub_request(:delete, url).to_return(:status => 200)
      end
      it { expect(storage.delete_file).to be_true }
      after (:each) do
        File.delete(list_file) if File.exists?(list_file)
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect(storage.delete_file).to be_false }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { expect(storage.delete_file).to be_false }
      end
      context 'not file' do
        before (:each) do
          list = [{'items' => {'test' => 'folder.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
        end
        it { expect(storage.delete_file).to be_false }
        after (:each) do
          File.delete(list_file) if File.exists?(list_file)
        end
      end
      context 'request fail' do
        before (:each) do
          list = [{'items' => {'test' => 'file.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:delete, url).to_return(:status => 404)
        end
        it { expect(storage.delete_file).to be_true }
        after (:each) do
          File.delete(list_file) if File.exists?(list_file)
        end
      end
    end
  end

  describe 'download_file' do
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::DOWNLOAD_FORMAT % [ 'file.1234', access_token ] }
    context 'success' do
      before (:each) do
        list = [{'items' => {'test' => 'file.1234'}}]
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        storage.file_name = 'test'
        body = JSON({'location' => 'http://localhost'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
        WebMock.stub_request(:get, 'http://localhost').
          to_return(:status => 200, :body => 'test', :headers => {})
      end
      it { expect(storage.download_file).to be_true }
      after (:each) do
        File.delete(list_file) if File.exists?(list_file)
        File.delete('test') if File.exists?('test')
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect(storage.download_file).to be_false }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { expect(storage.download_file).to be_false }
      end
      context 'not file' do
        before (:each) do
          list = [{'items' => {'test' => 'folder.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
        end
        it { expect(storage.download_file).to be_false }
        after (:each) do
          File.delete(list_file) if File.exists?(list_file)
        end
      end
      context 'request fail' do
        before (:each) do
          list = [{'items' => {'test' => 'file.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:get, url).to_return(:status => 404)
        end
        it { expect(storage.download_file).to be_false }
        after (:each) do
          File.delete(list_file) if File.exists?(list_file)
        end
      end
    end
  end

  describe 'upload_file' do
    it { pending 'pending' }
  end

  describe 'get_upload_file_name' do
    it { pending 'pending' }
  end

  describe 'delete_file_list' do
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      before (:each) do
        list = [{'items' => {'test' => 'file.1234'}}]
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { expect(storage.delete_file_list).to be_true }
      after (:each) do
        File.delete('test') if File.exists?('test')
      end
    end
  end

  describe 'file_exists?' do
    let(:storage) { create_onedrive }
    let(:url) { CloudDoor::OneDrive::ROOT_FORMAT % storage.token.access_token }
    let(:list_file) { storage.file_list.list_file }
    before (:each) do
      list = [{'items' => {'test' => 'file.1234'}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      storage.file_name    = 'test'
      storage.up_file_name = nil
    end
    context 'return true' do
      context 'file exists' do
        before (:each) do
          body = JSON({'data' => [{'id' => 'file.1234', 'name' => 'test'}]})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.file_exists?).to be_true }
      end
      context 'up_file exists' do
        before (:each) do
          storage.file_name    = nil
          storage.up_file_name = 'test'
          body = JSON({'data' => [{'id' => 'file.1234', 'name' => 'test'}]})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.file_exists?).to be_true }
      end
    end
    context 'return false' do
      context 'file not found' do
        before (:each) do
          body = JSON({'data' => [{'id' => 'file.5678', 'name' => 'test2'}]})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { expect(storage.file_exists?).to be_false }
      end
      context 'request fail' do
        before (:each) do
          WebMock.stub_request(:get, url).to_return(:status => 404)
        end
        it { expect(storage.file_exists?).to be_false }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'get_type_from_id' do
    subject { CloudDoor::OneDrive::get_type_from_id(target) }
    context 'file' do
      let(:target) { 'file.1234' }
      it { expect(subject).to eq 'file' }
    end
    context 'folder' do
      let(:target) { 'folder.1234' }
      it { expect(subject).to eq 'folder' }
    end
  end

  describe 'request_get_token' do
    let(:storage) { create_onedrive }
    context 'success' do
      let(:code) { '5678' }
      let(:url) { CloudDoor::OneDrive::TOKEN_URL + "?code=#{code}" }
      let(:body) { JSON({'access_token' => 'mock'}) }
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          with(
            :body => {
              'client_id'     => storage.config.client_id,
              'client_secret' => storage.config.client_secret,
              'redirect_uri'  => storage.config.redirect_url,
              'code'          => code,
              'grant_type'    => 'authorization_code'
            },
            :headers => {
              'Content-Type' => 'application/x-www-form-urlencoded',
            }
          ).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.send(:request_get_token, url)).to eq JSON.parse(body) }
    end
    context 'fail' do
      let(:url) { 'https://login.live.com/oauth20_desktop.srf' }
      it { expect(storage.send(:request_get_token, url)).to be_nil }
    end
  end

  describe 'request_refresh_token' do
    let(:storage) {
      storage = create_onedrive
      storage.token.refresh_token = 'refresh'
      storage
    }
    let(:mock_body) {
      {
        'client_id'     => storage.config.client_id,
        'client_secret' => storage.config.client_secret,
        'redirect_uri'  => storage.config.redirect_url,
        'grant_type'    => 'refresh_token',
        'refresh_token' => storage.token.refresh_token,
      }
    }
    let(:mock_header) { {'Content-Type' => 'application/x-www-form-urlencoded'} }
    context 'success' do
      let(:body) { JSON({'access_token' => 'mock'}) }
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          with(:body => mock_body, :headers => mock_header).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.send(:request_refresh_token)).to eq JSON.parse(body) }
    end
    context 'fail' do
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          with(:body => mock_body, :headers => mock_header).
          to_return(:status => 404)
      end
      it { expect(storage.send(:request_refresh_token)).to be_nil }
    end
  end

end
