require 'spec_helper'
require 'cloud_door'

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

def create_onedrive()
  storage = CloudDoor::OneDrive.new
  storage.client_id     = '1234'
  storage.client_secret = 'secret'
  storage.redirect_url  = 'localhost'
  storage.token_file    = '.token'
  storage
end

describe 'get_auth_url' do
  storage = create_onedrive
  url = CloudDoor::OneDrive::AUTH_FORMAT %
        [storage.client_id, CloudDoor::OneDrive::UPDATE_SCOPE, storage.redirect_url]
  it { expect(storage.get_auth_url).to eq url }
end

describe 'set_token' do
  before (:each) do
    open('.token', 'wb') { |file| file << 'token' }
  end
  storage = create_onedrive
  it do
    storage.set_token
    expect(storage.token).to eq 'token'
  end
  after (:each) do
    File.delete(storage.token_file) if File.exists?(storage.token_file)
  end
end

describe 'reset_token' do
  storage = create_onedrive
  code = '5678'
  url = CloudDoor::OneDrive::TOKEN_URL + "?code=#{code}"
  context 'success' do
    it do
      body = JSON({'access_token' => 'token'})
      WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
        to_return(:status => 200, :body => body, :headers => {})
      expect(storage.reset_token(url)).to be_true
      expect(File.exists?(storage.token_file)).to be_true
      expect(File.open(storage.token_file).read).to eq 'token'
    end
  end
  context 'fail' do
    it do
      WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
        to_return(:status => 404, :body => {}, :headers => {})
      expect(storage.reset_token(url)).to be_false
      expect(File.exists?(storage.token_file)).to be_false
    end
  end
  after (:each) do
    File.delete(storage.token_file) if File.exists?(storage.token_file)
  end
end

describe 'get_onedrive_info' do
  storage = create_onedrive
  context 'user' do
    url = CloudDoor::OneDrive::USER_FORMAT % storage.token
    it do
      body = JSON({'name' => 'onedrive'})
      WebMock.stub_request(:get, url).
        to_return(:status => 200, :body => body, :headers => {})
      expect(storage.get_onedrive_info('user', 'name')).to eq 'onedrive'
    end
  end
  context 'dir' do
    context 'root' do
      url = CloudDoor::OneDrive::ROOT_FORMAT % storage.token
      it do
        body = JSON({'data' => ['onedrive']})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
        expect(storage.get_onedrive_info('dir', 'data')).to eq ['onedrive']
      end
    end
    context 'dir' do
      file_id = '1234'
      url     = CloudDoor::OneDrive::DIR_FORMAT % [file_id, storage.token]
      it do
        body = JSON({'data' => ['onedrive']})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
        expect(storage.get_onedrive_info('dir', 'data', file_id)).to eq ['onedrive']
      end
    end
  end
  context 'file' do
    file_id = '1234'
    url     = CloudDoor::OneDrive::FILE_FORMAT % [file_id, storage.token]
    it do
      body = JSON({'name' => 'onedrive'})
      WebMock.stub_request(:get, url).
        to_return(:status => 200, :body => body, :headers => {})
      expect(storage.get_onedrive_info('file', 'name', file_id)).to eq 'onedrive'
    end
  end
  context 'fail' do
    url = CloudDoor::OneDrive::USER_FORMAT % storage.token
    context 'target not exists' do
      it do
        body = JSON({'name' => 'onedrive'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
        expect(storage.get_onedrive_info('member', 'name')).to be_nil
      end
    end
    context 'key not exists' do
      it do
        body = JSON({'name' => 'onedrive'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
        expect(storage.get_onedrive_info('user', 'firstname')).to be_nil
      end
    end
    context 'request fail' do
      it do
        WebMock.stub_request(:get, url).
          to_return(:status => 404, :body => {}, :headers => {})
        expect(storage.get_onedrive_info('user', 'name')).to be_nil
      end
    end
  end
end

describe 'show_dir' do
  storage = create_onedrive
  url     = CloudDoor::OneDrive::ROOT_FORMAT % storage.token
  context 'data exists' do
    it do
      body = JSON({'data' => [
        {'id' => '1234', 'name' => 'onedrive'},
        {'id' => '5678', 'name' => 'skydrive'}
      ]})
      WebMock.stub_request(:get, url).
        to_return(:status => 200, :body => body, :headers => {})
      expect(storage.show_dir).to eq ['onedrive [1234]', 'skydrive [5678]']
    end
  end
  context 'data not exists' do
    url = CloudDoor::OneDrive::ROOT_FORMAT % storage.token
    it do
      body = JSON({'data' => []})
      WebMock.stub_request(:get, url).
        to_return(:status => 200, :body => body, :headers => {})
      expect(storage.show_dir).to eq []
    end
  end
end

describe 'request_token' do
  storage = create_onedrive
  context 'success' do
    code = '5678'
    url = CloudDoor::OneDrive::TOKEN_URL + "?code=#{code}"
    it do
      body = JSON({'access_token' => 'mock'})
      WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
        with(
          :body => {
            'client_id'     => storage.client_id,
            'client_secret' => storage.client_secret,
            'code'          => code,
            'grant_type'    => 'authorization_code',
            'redirect_uri'  => storage.redirect_url
          },
          :headers => {
            'Content-Type' => 'application/x-www-form-urlencoded',
          }
        ).
        to_return(:status => 200, :body => body, :headers => {})
      expect(storage.send(:request_token, url)).to eq JSON.parse(body)
    end
  end
  context 'fail' do
    url = 'https://login.live.com/oauth20_desktop.srf'
    it { expect(storage.send(:request_token, url)).to be_nil }
  end
end
