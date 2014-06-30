require 'spec_helper'

RSpec.shared_examples 'http request fail' do
  context 'http request fail' do
    let(:status) { 401 }
    let(:body) { nil }
    it { expect { subject }.to raise_error(CloudDoor::UnauthorizedException) }
  end
end

describe 'OneDriveApi' do
  describe 'request_get_token' do
    subject { storage.request_get_token(code, client_id, client_secret, redirect_url) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:code) { '5678' }
    let(:client_id) { '1234' }
    let(:client_secret) { 'abcd' }
    let(:redirect_url) { 'redirect' }
    before(:each) do
      WebMock.stub_request(:post, CloudDoor::OneDriveApi::TOKEN_URL)
        .with(
          body: {
            'client_id'     => client_id,
            'client_secret' => client_secret,
            'redirect_uri'  => redirect_url,
            'code'          => code,
            'grant_type'    => 'authorization_code'
          },
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded'
          }
        )
        .to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:body) { JSON('access_token' => 'mock') }
      it { is_expected.to eq JSON.parse(body) }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'request_refresh_token' do
    subject { storage.request_refresh_token(refresh_token, client_id, client_secret, redirect_url) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:client_id) { '1234' }
    let(:client_secret) { 'abcd' }
    let(:redirect_url) { 'redirect' }
    let(:refresh_token) { 'refresh' }
    before(:each) do
      WebMock.stub_request(:post, CloudDoor::OneDriveApi::TOKEN_URL)
        .with(
          body: {
            'client_id'     => client_id,
            'client_secret' => client_secret,
            'redirect_uri'  => redirect_url,
            'grant_type'    => 'refresh_token',
            'refresh_token' => refresh_token
          },
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded'
          }
        )
        .to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:body) { JSON('access_token' => 'mock') }
      it { is_expected.to eq JSON.parse(body) }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'request_user' do
    subject { storage.request_user }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:url) { CloudDoor::OneDriveApi::USER_FORMAT % access_token }
    before(:each) do
      WebMock.stub_request(:get, url).to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'name' => 'onedrive'} }
      let(:body) { JSON(info) }
      it { is_expected.to eq info }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'request_dir' do
    subject { storage.request_dir(file_id) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:file_id) { 'folder.1234' }
    let(:url) { CloudDoor::OneDriveApi::DIR_FORMAT % [file_id, access_token] }
    before(:each) do
      WebMock.stub_request(:get, url).to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'data' => ['file1', 'file2']} }
      let(:body) { JSON(info) }
      it { is_expected.to eq info }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'request_file' do
    subject { storage.request_file(file_id) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:file_id) { 'file.1234' }
    let(:url) { CloudDoor::OneDriveApi::FILE_FORMAT % [file_id, access_token] }
    before(:each) do
      WebMock.stub_request(:get, url).to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'id' => 'file.1234', 'name' => 'file1'} }
      let(:body) { JSON(info) }
      it { is_expected.to eq info }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'request_download' do
    subject { storage.request_download(file_id) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:file_id) { 'file.1234' }
    let(:url) { CloudDoor::OneDriveApi::DOWNLOAD_FORMAT % [file_id, access_token] }
    before(:each) do
      WebMock.stub_request(:get, url).to_return(status: status, body: body)
      WebMock.stub_request(:get, 'http://localhost').to_return(status: status, body: file_body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'location' => 'http://localhost'} }
      let(:body) { JSON(info) }
      let(:file_body) { 'Onedrive' }
      it { is_expected.to eq file_body }
    end
    context 'fail' do
      context 'file not exists' do
        let(:status) { 200 }
        let(:body) { nil }
        let(:file_body) { nil }
        it { expect { subject }.to raise_error(CloudDoor::NoDataException) }
      end
      context 'http request fail' do
        let(:status) { 401 }
        let(:body) { nil }
        let(:file_body) { nil }
        it { expect { subject }.to raise_error(CloudDoor::UnauthorizedException) }
      end
    end
  end

  describe 'request_upload' do
    subject { storage.request_upload(file_path, parent_id) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:file_path) { 'upload_test' }
    let(:parent_id) { 'folder.1234' }
    let(:url) { CloudDoor::OneDriveApi::UPLOAD_FORMAT % [parent_id, access_token] }
    before(:each) do
      WebMock.stub_request(:post, url).to_return(status: status, body: body)
      open(file_path, 'wb') { |file| file << 'upload_test' }
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'id' => 'file.1234', 'name' => file_path} }
      let(:body) { JSON(info) }
      it { is_expected.to eq info }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
    after(:each) do
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  describe 'request_delete' do
    subject { storage.request_delete(file_id) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:file_id) { 'file.1234' }
    let(:url) { CloudDoor::OneDriveApi::DELETE_FORMAT % [file_id, access_token] }
    before(:each) do
      WebMock.stub_request(:delete, url).to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'id' => 'file.1234', 'name' => 'file1'} }
      let(:body) { JSON(info) }
      it { is_expected.to eq info }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'request_mkdir' do
    subject { storage.request_mkdir(mkdir_name, parent_id) }
    let(:access_token) { 'token' }
    let(:storage) { CloudDoor::OneDriveApi.new(access_token) }
    let(:mkdir_name) { 'folder2' }
    let(:parent_id) { 'folder.1234' }
    let(:url) { CloudDoor::OneDriveApi::MKDIR_FORMAT % parent_id }
    before(:each) do
      WebMock.stub_request(:post, url)
        .with(
          body: JSON('name' => mkdir_name),
          headers: {
            'Authorization' => "Bearer #{access_token}",
            'Content-Type'  => 'application/json'
          }
        )
        .to_return(status: status, body: body)
    end
    context 'success' do
      let(:status) { 200 }
      let(:info) { {'id' => 'folder.5678', 'name' => mkdir_name} }
      let(:body) { JSON(info) }
      it { is_expected.to eq info }
    end
    context 'fail' do
      it_behaves_like 'http request fail'
    end
  end

  describe 'make_auth_url' do
    subject { CloudDoor::OneDriveApi.make_auth_url(client_id, redirect_url) }
    let(:client_id) { '1234' }
    let(:redirect_url) { 'redirect' }
    let(:auth_url) do
      CloudDoor::OneDriveApi::AUTH_FORMAT %
        [client_id, CloudDoor::OneDriveApi::UPDATE_SCOPE, redirect_url]
    end
    it { is_expected.to eq auth_url }
  end
end
