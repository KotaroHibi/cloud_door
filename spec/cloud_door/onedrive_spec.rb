require 'spec_helper'

describe 'OneDrive' do
  describe 'reset_token' do
    subject { storage.reset_token(token_value) }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:token_value) { {'access_token' => 'token2'} }
    context 'success' do
      it do
        subject
        expect(storage.token.access_token).to eq 'token2'
      end
    end
    context 'fail' do
      context 'not Token class' do
        before(:each) do
          storage.token = 'token'
        end
        it { expect { subject }.to raise_error(CloudDoor::TokenClassException) }
      end
    end
  end

  describe 'show_user' do
    subject { storage.show_user }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    context 'success' do
      let(:posit) { {'name' => 'onedrive'} }
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_user)
          .and_return(posit)
        is_expected.to eq posit
      end
    end
  end

  describe 'show_files' do
    subject { storage.show_files }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      context 'data exists' do
        let(:posit) do
          {'data' => [
            {'id' => 'file.1234', 'name' => 'file1', 'type' => 'file'},
            {'id' => 'file.5678', 'name' => 'file2', 'type' => 'file'}
          ]}
        end
        let(:result) do
          {
            'file1' => {'id' => 'file.1234', 'type' => 'file'},
            'file2' => {'id' => 'file.5678', 'type' => 'file'}
          }
        end
        before(:each) do
          storage.file_name = nil
        end
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
            .with(CloudDoor::OneDrive::ROOT_ID)
            .and_return(posit)
          is_expected.to eq result
        end
      end
      context 'data not exists' do
        let(:posit) { {'data' => []} }
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
            .with(CloudDoor::OneDrive::ROOT_ID)
            .and_return(posit)
          is_expected.to eq({})
        end
      end
    end
    context 'fail' do
      context 'file id not exits' do
        before(:each) do
          storage.file_name = 'test'
        end
        it { expect { subject }.to raise_error(CloudDoor::SetIDException) }
      end
      context 'not directory' do
        before(:each) do
          list = [{'items' => {'test' => {'id' => 'file.1234', 'type' => 'file'}}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'test'
        end
        it { expect { subject }.to raise_error(CloudDoor::NotDirectoryException) }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'show_current_dir' do
    subject { storage.show_current_dir }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    it { is_expected.to eq('/top') }
  end

  describe 'show_property' do
    subject { storage.show_property }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    before(:each) do
      list = [{'items' => {'file1' => {'id' => 'file.1234', 'type' => 'file'}}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      context 'file exists' do
        let(:posit) do
          {
            'name'         => 'file',
            'id'           => 'file.1234',
            'type'         => 'file',
            'size'         => 1024,
            'created_time' => '2014-06-01 12:20:30',
            'updated_time' => '2014-06-05 13:30:40'
          }
        end
        before(:each) do
          storage.file_id   = 'file.1234'
          storage.file_name = 'file1'
          storage.stub(:file_exists?).and_return(true)
        end
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_file)
            .with(storage.file_id)
            .and_return(posit)
          is_expected.to eq posit
        end
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect { subject }.to raise_error(CloudDoor::FileNameEmptyException) }
      end
      context 'file id not exits' do
        before(:each) do
          storage.file_name = 'test'
        end
        it { expect { subject }.to raise_error(CloudDoor::SetIDException) }
      end
      context 'file not exits on cloud' do
        before(:each) do
          storage.file_id   = 'file.1234'
          storage.file_name = 'file1'
          storage.stub(:file_exists?).and_return(false)
        end
        it { expect { subject }.to raise_error(CloudDoor::FileNotExistsException) }
      end
      context 'no data' do
        let(:posit) { nil }
        let(:posit_dir) do
          JSON('data' => [
            {'id' => 'file.1234', 'name' => 'file1', 'type' => 'file'},
            {'id' => 'file.5678', 'name' => 'file2', 'type' => 'file'}
          ])
        end
        before(:each) do
          storage.file_id   = 'file.1234'
          storage.file_name = 'file1'
          storage.stub(:file_exists?).and_return(true)
          CloudDoor::OneDriveApi.any_instance.stub(:request_file)
            .and_return(posit)
        end
        it { expect { subject }.to raise_error(CloudDoor::NoDataException) }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'pick_cloud_info' do
    subject { storage.pick_cloud_info(method, key) }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    context 'user' do
      let(:method) { 'request_user' }
      let(:key) { 'name' }
      let(:posit) { {'name' => 'onedrive'} }
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_user)
          .and_return(posit)
        is_expected.to eq 'onedrive'
      end
    end
    context 'dir' do
      let(:method) { 'request_dir' }
      let(:key) { 'data' }
      let(:posit) { {'data' => ['file1']} }
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
          .with(CloudDoor::OneDrive::ROOT_ID)
          .and_return(posit)
        is_expected.to eq ['file1']
      end
    end
    context 'file' do
      let(:storage) { create_storage(CloudDoor::OneDrive, 'file.1234') }
      let(:method) { 'request_file' }
      let(:key) { 'name' }
      let(:posit) { {'name' => 'file1', 'id' => 'file.1234'} }
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_file)
          .with(storage.file_id)
          .and_return(posit)
        is_expected.to eq 'file1'
      end
    end
    context 'fail' do
      let(:method) { 'request_user' }
      let(:key) { 'name' }
      let(:posit) { {'name' => 'onedrive'} }
      before(:each) do
        CloudDoor::OneDriveApi.any_instance.stub(:request_user)
          .and_return(posit)
      end
      context 'method not exists' do
        let(:method) { 'request_member' }
        it { expect { subject }.to raise_error(CloudDoor::RequestMethodNotFoundException) }
      end
      context 'data not exists' do
        let(:posit) { nil }
        it { expect { subject }.to raise_error(CloudDoor::NoDataException) }
      end
      context 'key not exists' do
        let(:key) { 'firstname' }
        it { expect { subject }.to raise_error(CloudDoor::RequestPropertyNotFoundException) }
      end
    end
  end

  describe 'download_file' do
    subject { storage.download_file }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      let(:posit) { 'test' }
      before(:each) do
        list = [{'items' => {'file1' => {'id' => 'file.1234', 'type' => 'file'}}}]
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        storage.file_name = 'file1'
        storage.file_id   = 'file.1234'
      end
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_download)
          .with(storage.file_id)
          .and_return(posit)
        is_expected.to be_truthy
      end
      after(:each) do
        File.delete('file1') if File.exist?('file1')
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect { subject }.to raise_error(CloudDoor::FileNameEmptyException) }
      end
      context 'file id not exits' do
        before(:each) do
          storage.file_name = 'test'
        end
        it { expect { subject }.to raise_error(CloudDoor::SetIDException) }
      end
      context 'not file' do
        before(:each) do
          list = [{'items' => {'folder1' => {'id' => 'folder.1234', 'type' => 'folder'}}}]
          open(list_file, 'wb') { |file| file << Marshal.dump(list) }
          storage.file_name = 'folder1'
        end
        it { expect { subject }.to raise_error(CloudDoor::NotFileException) }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'upload_file' do
    subject { storage.upload_file }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    let(:up_file) { 'upload' }
    context 'success' do
      let(:posit) { {'id' => 'file.1234', 'name' => 'file1'} }
      let(:posit_dir) { {'data' => [{'id' => 'file.1234', 'name' => 'file1'}]} }
      before(:each) do
        open(up_file, 'wb') { |file| file << 'upload' }
        storage.up_file_name = up_file
      end
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_upload)
          .with(storage.up_file_name, CloudDoor::OneDrive::ROOT_ID)
          .and_return(posit)
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
          .with(CloudDoor::OneDrive::ROOT_ID)
          .and_return(posit_dir)
        is_expected.to be_truthy
      end
    end
    context 'fail' do
      context 'upload file name not input' do
        it { expect { subject }.to raise_error(CloudDoor::FileNameEmptyException) }
      end
      context 'file not exits' do
        before(:each) do
          storage.up_file_name = up_file
        end
        it { expect { subject }.to raise_error(CloudDoor::FileNotExistsException) }
      end
    end
    after(:each) do
      File.delete(up_file) if File.exist?(up_file)
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'delete_file' do
    subject { storage.delete_file }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      let(:posit) { {'id' => 'file.1234', 'name' => 'file1'} }
      let(:posit_dir) { {'data' => [{'id' => 'file.5678', 'name' => 'file2'}]} }
      before(:each) do
        list = [{'items' => {'file1' => {'id' => 'file.1234', 'type' => 'file'}}}]
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
        storage.file_name = 'file1'
        storage.file_id   = 'file.1234'
      end
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_delete)
          .with(storage.file_id)
          .and_return(posit)
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
          .with(CloudDoor::OneDrive::ROOT_ID)
          .and_return(posit_dir)
        is_expected.to be_truthy
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect { subject }.to raise_error(CloudDoor::FileNameEmptyException) }
      end
      context 'file id not exits' do
        before(:each) do
          storage.file_name = 'test'
        end
        it { expect { subject }.to raise_error(CloudDoor::SetIDException) }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'make_directory' do
    subject { storage.make_directory }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    context 'success' do
      let(:posit) { {'id' => 'folder.1234', 'name' => 'folder1'} }
      let(:posit_dir) { {'data' => [{'id' => 'folder.1234', 'name' => 'folder1'}]} }
      before(:each) do
        storage.mkdir_name = 'folder1'
      end
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_mkdir)
          .with(storage.mkdir_name, CloudDoor::OneDrive::ROOT_ID)
          .and_return(posit)
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
          .with(CloudDoor::OneDrive::ROOT_ID)
          .and_return(posit_dir)
        is_expected.to be_truthy
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect { subject }.to raise_error(CloudDoor::DirectoryNameEmptyException) }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'assign_upload_file_name' do
    subject { storage.assign_upload_file_name }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    context 'file' do
      let(:file) { 'testfile' }
      before(:each) do
        storage.up_file_name = file
      end
      it { is_expected.to eq file }
    end
    context 'directory' do
      let(:file) { 'testdir' }
      before(:each) do
        storage.up_file_name = file
        Dir.mkdir(file)
      end
      it { is_expected.to eq "#{file}.zip" }
      after(:each) do
        Dir.rmdir(file) if File.exist?(file)
      end
    end
  end

  describe 'delete_file_list' do
    subject { storage.delete_file_list }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    before(:each) do
      list = [{'items' => {'file1' => {'id' => 'file.1234', 'type' => 'file'}}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    it do
      expect(File.exist?(list_file)).to be_truthy
      subject
      expect(File.exist?(list_file)).to be_falsey
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'file_exists?' do
    subject { storage.file_exists? }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    before(:each) do
      list = [{'items' => {'file1' => {'id' => 'file.1234', 'type' => 'file'}}}]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'return true' do
      let(:posit) { {'data' => [{'id' => 'file.1234', 'name' => 'file1'}]} }
      context 'file exists' do
        before(:each) do
          storage.file_name    = 'file1'
          storage.up_file_name = nil
          storage.mkdir_name   = nil
        end
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
            .with(CloudDoor::OneDrive::ROOT_ID)
            .and_return(posit)
          is_expected.to be_truthy
        end
      end
      context 'up_file exists' do
        before(:each) do
          storage.file_name    = nil
          storage.up_file_name = 'file1'
          storage.mkdir_name   = nil
        end
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
            .with(CloudDoor::OneDrive::ROOT_ID)
            .and_return(posit)
          is_expected.to be_truthy
        end
      end
      context 'mkdir exists' do
        before(:each) do
          storage.file_name    = nil
          storage.up_file_name = nil
          storage.mkdir_name   = 'file1'
        end
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_dir)
            .with(CloudDoor::OneDrive::ROOT_ID)
            .and_return(posit)
          is_expected.to be_truthy
        end
      end
    end
    context 'return false' do
      let(:posit) { {'data' => [{'id' => 'file.5678', 'name' => 'file2'}]} }
      context 'file not found' do
        before(:each) do
          storage.file_name    = 'file1'
          storage.up_file_name = nil
          storage.mkdir_name   = nil
          CloudDoor::OneDriveApi.any_instance.stub(:request_dir)
            .and_return(posit)
        end
        it { is_expected.to be_falsey }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'has_file?' do
    subject { storage.has_file? }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    before(:each) do
      file1   = {'id' => 'file.1234', 'type' => 'file'}
      folder1 = {'id' => 'folder.5678', 'type' => 'folder'}
      list = [
        {'items' => {'file1' => file1, 'folder1' => folder1}}
      ]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'return true' do
      context 'count > 0' do
        let(:posit) { {'count' => 5} }
        before(:each) do
          storage.file_name = 'folder1'
          storage.stub(:file_exists?).and_return(true)
        end
        it do
          expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_file)
            .with('folder.5678')
            .and_return(posit)
          is_expected.to be_truthy
        end
      end
    end
    context 'return false' do
      context 'target is file' do
        before(:each) do
          storage.file_name = 'file1'
        end
        it { is_expected.to be_falsey }
      end
      context 'count == 0' do
        let(:posit) { {'count' => 0} }
        before(:each) do
          storage.file_name = 'folder1'
          storage.stub(:file_exists?).and_return(true)
          CloudDoor::OneDriveApi.any_instance.stub(:request_file)
            .and_return(posit)
        end
        it { is_expected.to be_falsey }
      end
    end
    context 'fail' do
      context 'file name not input' do
        it { expect { subject }.to raise_error(CloudDoor::FileNameEmptyException) }
      end
      context 'file id not exits' do
        before(:each) do
          storage.file_name = 'test'
        end
        it { expect { subject }.to raise_error(CloudDoor::SetIDException) }
      end
      context 'data not found' do
        let(:posit) { nil }
        before(:each) do
          storage.file_name = 'folder1'
          storage.stub(:file_exists?).and_return(true)
          CloudDoor::OneDriveApi.any_instance.stub(:request_file)
            .and_return(posit)
        end
        it { expect { subject }.to raise_error(CloudDoor::NoDataException) }
      end
    end
    after(:each) do
      File.delete(list_file) if File.exist?(list_file)
    end
  end

  describe 'file?' do
    subject { storage.file? }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:list_file) { storage.file_list.list_file }
    before(:each) do
      file1   = {'id' => 'file.1234', 'name' => 'file1', 'type' => 'file'}
      folder1 = {'id' => 'folder.5678', 'name' => 'folder1', 'type' => 'folder'}
      list = [
        {'items' => {'file1' => file1, 'folder1' => folder1}}
      ]
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'return true' do
      context 'file' do
        before(:each) do
          storage.file_name = 'file1'
        end
        it { is_expected.to be_truthy }
      end
    end
    context 'return false' do
      context 'file name not input' do
        it { is_expected.to be_falsey }
      end
      context 'parent' do
        before(:each) do
          storage.file_name = '../'
        end
        it { is_expected.to be_falsey }
      end
      context 'folder' do
        before(:each) do
          storage.file_name = 'folder1'
        end
        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'load_token' do
    let(:token) { Fabricate.build(:token) }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    let(:token_file) { storage.token.token_file }
    before(:each) do
      open(token_file, 'wb') { |file| file << Marshal.dump(token) }
    end
    it do
      result = storage.load_token('test_token')
      expect(result.is_a?(CloudDoor::Token)).to be_truthy
    end
    after(:each) do
      File.delete(token_file) if File.exist?(token_file)
    end
  end

  describe 'refresh_token' do
    subject { storage.refresh_token }
    let(:storage) { create_storage(CloudDoor::OneDrive) }
    context 'success' do
      let(:posit) { {'access_token' => 'token2'} }
      it do
        expect_any_instance_of(CloudDoor::OneDriveApi).to receive(:request_refresh_token)
          .and_return(posit)
        subject
        expect(storage.token.access_token).to eq 'token2'
      end
    end
    context 'fail' do
      context 'not Token class' do
        before(:each) do
          storage.token = 'token'
        end
        it { expect { subject }.to raise_error(CloudDoor::TokenClassException) }
      end
      context 'not Token class' do
        let(:posit) { nil }
        before(:each) do
          CloudDoor::OneDriveApi.any_instance.stub(:request_refresh_token)
            .and_return(posit)
        end
        it { expect { subject }.to raise_error(CloudDoor::NoDataException) }
      end
    end
  end
end
