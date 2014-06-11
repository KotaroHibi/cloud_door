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
  storage.token.token_file     = '.testtoken'
  storage.token.refresh_token  = 'refresh'
  storage.config.client_id     = '1234'
  storage.config.client_secret = 'abcd'
  storage.config.redirect_url  = 'onedrive'
  storage.file_list.list_file  = '.testlist'
  storage
end

describe 'OneDrive' do
  describe 'get_auth_url' do
    subject { storage.get_auth_url }
    let(:storage) { create_onedrive }
    let(:url) {
      CloudDoor::OneDrive::AUTH_FORMAT %
        [storage.config.client_id, CloudDoor::OneDrive::UPDATE_SCOPE, storage.config.redirect_url]
    }
    it { is_expected.to eq url }
  end

  describe 'set_token' do
    let(:token) { Fabricate.build(:token) }
    let(:storage) { create_onedrive }
    let(:token_file) { storage.token.token_file }
    before (:each) do
      open(token_file, 'wb') { |file| file << Marshal.dump(token) }
    end
    it {
      token = storage.set_token(token_file)
      expect(token.is_a?(Token)).to be_truthy
    }
    after (:each) do
      File.delete(token_file) if File.exists?(token_file)
    end
  end

  describe 'reset_token' do
    subject { storage.reset_token(url) }
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
      it { is_expected.to be_truthy }
      it { expect(File.exists?(token_file)).to be_truthy }
      it { expect(Marshal.load(File.open(token_file).read).access_token).to eq 'token' }
      after (:all) do
        File.delete('.testtoken') if File.exists?('.testtoken')
      end
    end
    context 'fail' do
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 404)
      end
      it { is_expected.to be_falsey }
      it { expect(File.exists?(token_file)).to be_falsey }
    end
  end

  describe 'refresh_token' do
    subject { storage.refresh_token }
    let(:storage) { create_onedrive }
    let(:token_file) { storage.token.token_file }
    context 'success' do
      body = JSON({'access_token' => 'token'})
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { is_expected.to be_truthy }
      it { expect(File.exists?(token_file)).to be_truthy }
      it { expect(Marshal.load(File.open(token_file).read).access_token).to eq 'token' }
      after (:all) do
        File.delete('.testtoken') if File.exists?('.testtoken')
      end
    end
    context 'fail' do
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          to_return(:status => 404)
      end
      it { is_expected.to be_falsey }
      it { expect(File.exists?(token_file)).to be_falsey }
    end
  end

  describe 'get_onedrive_info' do
    subject { storage.get_onedrive_info(target, key) }
    let(:storage) { create_onedrive }
    let(:access_token) { storage.token.access_token }
    context 'user' do
      let(:target) { 'user' }
      let(:key) { 'name' }
      let(:url) { CloudDoor::OneDrive::USER_FORMAT % access_token }
      before (:each) do
        body = JSON({'name' => 'onedrive'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      it { is_expected.to eq 'onedrive' }
    end
    context 'dir' do
      let(:target) { 'dir' }
      let(:key) { 'data' }
      context 'root' do
        let(:url) { CloudDoor::OneDrive::DIR_FORMAT % [CloudDoor::OneDrive::ROOT_ID, access_token] }
        before (:each) do
          body = JSON({'data' => ['onedrive']})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to eq ['onedrive'] }
      end
      context 'dir' do
        let(:storage) { create_onedrive('1234') }
        let(:url) { CloudDoor::OneDrive::DIR_FORMAT % [storage.file_id, access_token] }
        before (:each) do
          body = JSON({'data' => ['onedrive']})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to eq ['onedrive'] }
      end
    end
    context 'file' do
      let(:storage) { create_onedrive('1234') }
      let(:target) { 'file' }
      let(:url) { CloudDoor::OneDrive::FILE_FORMAT % [storage.file_id, access_token] }
      before (:each) do
        body = JSON({'name' => 'onedrive', 'id' => '1234'})
        WebMock.stub_request(:get, url).
          to_return(:status => 200, :body => body, :headers => {})
      end
      context 'key set' do
        let(:key) { 'name' }
        it { is_expected.to eq 'onedrive' }
      end
      context 'key not set' do
        let(:key) { nil }
        it { is_expected.to eq({'name' => 'onedrive', 'id' => '1234'}) }
      end
    end
    context 'fail' do
      let(:url) { CloudDoor::OneDrive::USER_FORMAT % access_token }
      let(:target) { 'user' }
      let(:key) { 'name' }
      context 'target not exists' do
        let(:target) { 'member' }
        before (:each) do
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to be_nil }
      end
      context 'key not exists' do
        let(:key) { 'firstname' }
        before (:each) do
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to be_nil }
      end
      context 'request fail' do
        before (:each) do
          WebMock.stub_request(:get, url).
            to_return(:status => 404, :body => {}, :headers => {})
        end
        it { is_expected.to be_nil }
      end
    end
  end

  describe 'show_files' do
    subject { storage.show_files }
    let(:storage) { create_onedrive }
    let(:url) {
      CloudDoor::OneDrive::DIR_FORMAT % [CloudDoor::OneDrive::ROOT_ID, storage.token.access_token]
    }
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
      it { is_expected.to eq({'onedrive' => 'file.1234', 'skydrive' => 'file.5678'}) }
    end
    context 'fail' do
      context 'data not exists' do
        before (:each) do
          body = JSON({'data' => []})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to eq({}) }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { is_expected.to be_nil }
      end
      context 'not directory' do
        before (:each) do
          list = [{'items' => {'test' => 'file.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
        end
        it { is_expected.to be_nil }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'show_current_dir' do
    subject { storage.show_current_dir }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    it { is_expected.to eq('/top') }
  end

  describe 'show_property' do
    subject { storage.show_property }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::FILE_FORMAT % [storage.file_id, access_token] }
    before (:each) do
      list = [{'items' => {'file' => 'file.1234', 'folder' => 'folder.5678'}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      context 'file' do
        let(:info) { {
          'name'         => 'file',
          'id'           => 'file.1234',
          'type'         => 'file',
          'size'         => 1024,
          'created_time' => '2014-06-01 12:20:30',
          'updated_time' => '2014-06-05 13:30:40',
        } }
        before (:each) do
          storage.file_id = 'file.1234'
          storage.file_name = 'file'
          body = JSON(info)
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to eq info }
      end
      context 'folder' do
        let(:info) { {
          'name'         => 'folder',
          'id'           => 'folder.5678',
          'type'         => 'folder',
          'size'         => 1024,
          'count'        => 5,
          'created_time' => '2014-06-01 12:20:30',
          'updated_time' => '2014-06-05 13:30:40',
        } }
        before (:each) do
          storage.file_id = 'folder.5678'
          storage.file_name = 'folder'
          body = JSON(info)
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to eq info }
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { is_expected.to be_empty  }
      end
      context 'request fail' do
        before (:each) do
          storage.file_name = 'test'
          WebMock.stub_request(:get, url).to_return(:status => 404)
        end
        it { is_expected.to be_empty  }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'delete_file' do
    subject { storage.delete_file }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::DELETE_FORMAT % [ 'file.1234', access_token ] }
    let(:info_url) { CloudDoor::OneDrive::DIR_FORMAT % [ CloudDoor::OneDrive::ROOT_ID, access_token ] }
    context 'success' do
      before (:each) do
        list = [{'items' => {'test' => 'file.1234'}}]
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        storage.file_name = 'test'
        WebMock.stub_request(:delete, url).to_return(:status => 200)
        WebMock.stub_request(:get, info_url).to_return(:status => 200)
      end
      it { is_expected.to be_truthy }
    end
    context 'fail' do
      context 'file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { is_expected.to be_falsey }
      end
      context 'request fail' do
        before (:each) do
          list = [{'items' => {'test' => 'file.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
          WebMock.stub_request(:delete, url).to_return(:status => 404)
          WebMock.stub_request(:get, info_url).to_return(:status => 404)
        end
        it { is_expected.to be_truthy }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'download_file' do
    subject { storage.download_file }
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
      it { is_expected.to be_truthy }
      after (:each) do
        File.delete('test') if File.exists?('test')
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { is_expected.to be_falsey }
      end
      context 'not file' do
        before (:each) do
          list = [{'items' => {'test' => 'folder.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
        end
        it { is_expected.to be_falsey }
      end
      context 'request fail' do
        before (:each) do
          list = [{'items' => {'test' => 'file.1234'}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
          body = JSON({'name' => 'onedrive'})
          WebMock.stub_request(:get, url).to_return(:status => 404)
        end
        it { is_expected.to be_falsey }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'upload_file' do
    subject { storage.upload_file }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:up_file) { 'upload' }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::UPLOAD_FORMAT % [ CloudDoor::OneDrive::ROOT_ID, access_token ] }
    let(:info_url) { CloudDoor::OneDrive::DIR_FORMAT % [ CloudDoor::OneDrive::ROOT_ID, access_token ] }
    context 'success' do
      before (:each) do
        open(up_file, 'wb') { |file| file << 'upload' }
        storage.up_file_name = up_file
        WebMock.stub_request(:post, url).to_return(:status => 200)
        WebMock.stub_request(:get, info_url).to_return(:status => 200)
      end
      it { is_expected.to be_truthy }
    end
    context 'fail' do
      context 'upload file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'file not exits' do
        before (:each) do
          storage.up_file_name = up_file
        end
        it { is_expected.to be_falsey }
      end
      context 'request fail' do
        before (:each) do
          open(up_file, 'wb') { |file| file << 'upload' }
          storage.up_file_name = up_file
          WebMock.stub_request(:post, url).to_return(:status => 404)
          WebMock.stub_request(:get, info_url).to_return(:status => 404)
        end
        it { is_expected.to be_truthy }
      end
    end
    after (:each) do
      File.delete(up_file) if File.exists?(up_file)
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'get_upload_file_name' do
    subject { storage.get_upload_file_name }
    let(:storage) { create_onedrive }
    context 'file' do
      let(:file) { 'testfile' }
      before (:each) do
        storage.up_file_name = file
      end
      it { is_expected.to eq file }
    end
    context 'directory' do
      let(:file) { 'testdir' }
      before (:each) do
        storage.up_file_name = file
        Dir.mkdir(file)
      end
      it { is_expected.to eq "#{file}.zip" }
      after (:each) do
        Dir.rmdir(file) if File.exists?(file)
      end
    end
  end

  describe 'make_directory' do
    subject { storage.make_directory }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::MKDIR_FORMAT % [ CloudDoor::OneDrive::ROOT_ID ] }
    let(:info_url) { CloudDoor::OneDrive::DIR_FORMAT % [ CloudDoor::OneDrive::ROOT_ID, access_token ] }
    context 'success' do
      before (:each) do
        storage.mkdir_name = 'dir'
        WebMock.stub_request(:post, url).
          to_return(:status => 200)
        WebMock.stub_request(:get, info_url).to_return(:status => 200)
      end
      it { is_expected.to be_truthy }
    end
    context 'fail' do
      context 'file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'request fail' do
        before (:each) do
          storage.mkdir_name = 'dir'
          WebMock.stub_request(:post, url).to_return(:status => 404)
          WebMock.stub_request(:get, info_url).to_return(:status => 404)
        end
        it { is_expected.to be_truthy }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'delete_file_list' do
    subject { storage.delete_file_list }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    before (:each) do
      list = [{'items' => {'test' => 'file.1234'}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    it { is_expected.to be_truthy }
    after (:each) do
      File.delete('test') if File.exists?('test')
    end
  end

  describe 'file_exists?' do
    subject { storage.file_exists? }
    let(:storage) { create_onedrive }
    let(:url) {
      CloudDoor::OneDrive::DIR_FORMAT % [CloudDoor::OneDrive::ROOT_ID, storage.token.access_token]
    }
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
        it { is_expected.to be_truthy }
      end
      context 'up_file exists' do
        before (:each) do
          storage.file_name    = nil
          storage.up_file_name = 'test'
          body = JSON({'data' => [{'id' => 'file.1234', 'name' => 'test'}]})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to be_truthy }
      end
    end
    context 'return false' do
      context 'file not found' do
        before (:each) do
          body = JSON({'data' => [{'id' => 'file.5678', 'name' => 'test2'}]})
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to be_falsey }
      end
      context 'request fail' do
        before (:each) do
          WebMock.stub_request(:get, url).to_return(:status => 404)
        end
        it { is_expected.to be_falsey }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'has_file?' do
    subject { storage.has_file? }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::FILE_FORMAT % ['folder.5678', access_token] }
    before (:each) do
      list = [{'items' => {'file' => 'file.1234', 'folder' => 'folder.5678'}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'return true' do
      context 'folder' do
        let(:info) { {
          'name'         => 'folder',
          'id'           => 'folder.5678',
          'type'         => 'folder',
          'size'         => 1024,
          'count'        => 5,
          'created_time' => '2014-06-01 12:20:30',
          'updated_time' => '2014-06-05 13:30:40',
        } }
        before (:each) do
          storage.file_name = 'folder'
          body = JSON(info)
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to be_truthy }
      end
    end
    context 'return false' do
      context 'file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'file id not exits' do
        before (:each) do
          storage.file_name = 'test'
        end
        it { is_expected.to be_falsey }
      end
      context 'target is file' do
        before (:each) do
          storage.file_name = 'file'
        end
        it { is_expected.to be_falsey }
      end
      context 'count is 0' do
        let(:info) { {
          'name'         => 'folder',
          'id'           => 'folder.5678',
          'type'         => 'folder',
          'size'         => 1024,
          'count'        => 0,
          'created_time' => '2014-06-01 12:20:30',
          'updated_time' => '2014-06-05 13:30:40',
        } }
        before (:each) do
          storage.file_name = 'folder'
          body = JSON(info)
          WebMock.stub_request(:get, url).
            to_return(:status => 200, :body => body, :headers => {})
        end
        it { is_expected.to be_falsey }
      end
      context 'request fail' do
        before (:each) do
          storage.file_name = 'folder'
          WebMock.stub_request(:get, url).to_return(:status => 404)
        end
        it { is_expected.to be_falsey  }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'is_file?' do
    subject { storage.is_file? }
    let(:storage) { create_onedrive }
    context 'file' do
      before (:each) do
        storage.file_id = 'file.1234'
      end
      it { is_expected.to be_truthy }
    end
    context 'folder' do
      before (:each) do
        storage.file_id = 'folder.1234'
      end
      it { is_expected.to be_falsey }
    end
  end

  describe 'get_type_from_id' do
    subject { CloudDoor::OneDrive::get_type_from_id(target) }
    context 'file' do
      let(:target) { 'file.1234' }
      it { is_expected.to eq 'file' }
    end
    context 'folder' do
      let(:target) { 'folder.1234' }
      it { is_expected.to eq 'folder' }
    end
  end

  describe 'request_get_token' do
    subject { storage.send(:request_get_token, url) }
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
      it { is_expected.to eq JSON.parse(body) }
    end
    context 'fail' do
      let(:url) { 'https://login.live.com/oauth20_desktop.srf' }
      it { is_expected.to be_nil }
    end
  end

  describe 'request_refresh_token' do
    subject { storage.send(:request_refresh_token) }
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
      it { is_expected.to eq JSON.parse(body) }
    end
    context 'fail' do
      before (:each) do
        WebMock.stub_request(:post, CloudDoor::OneDrive::TOKEN_URL).
          with(:body => mock_body, :headers => mock_header).
          to_return(:status => 404)
      end
      it { is_expected.to be_nil }
    end
  end

  describe 'request_mkdir' do
    subject { storage.send(:request_mkdir) }
    let(:storage) { create_onedrive }
    let(:list_file) { storage.file_list.list_file }
    let(:access_token) { storage.token.access_token }
    let(:url) { CloudDoor::OneDrive::MKDIR_FORMAT % [ CloudDoor::OneDrive::ROOT_ID ] }
    let(:mock_body) { JSON({'name' => storage.mkdir_name}) }
    let(:mock_header) { {
      'Authorization' => "Bearer",
      'Content-Type'  => 'application/json'
    } }
    context 'success' do
      let(:body) { JSON({'result' => 'success'}) }
      before (:each) do
        storage.mkdir_name = 'dir'
        WebMock.stub_request(:post, url).
          with(:body => mock_body, :headers => mock_header).
          to_return(:status => 200, :body => body, :header => {})
      end
      it { is_expected.to eq JSON.parse(body) }
    end
    context 'fail' do
      before (:each) do
        storage.mkdir_name = 'dir'
        WebMock.stub_request(:post, url).
          with(:body => mock_body, :headers => mock_header).
          to_return(:status => 404)
      end
      it { is_expected.to be_falsey }
    end
  end
end
