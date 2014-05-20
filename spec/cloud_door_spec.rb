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
  storage.file_id = file_id
  storage.token.token_file = '.test'
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
      storage.set_token
    end
    it { expect(storage.token).to be_true }
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

  describe 'show_dir' do
    let(:storage) { create_onedrive }
    let(:url) { CloudDoor::OneDrive::ROOT_FORMAT % storage.token.access_token }
    context 'data exists' do
      before (:each) do
        body = JSON({'data' => [
          {'id' => '1234', 'name' => 'onedrive'},
          {'id' => '5678', 'name' => 'skydrive'}
        ]})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.show_dir).to eq ['onedrive [1234]', 'skydrive [5678]'] }
    end
    context 'data not exists' do
      before (:each) do
        body = JSON({'data' => []})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { expect(storage.show_dir).to eq [] }
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
              'code'          => code,
              'grant_type'    => 'authorization_code',
              'redirect_uri'  => storage.config.redirect_url
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
end
