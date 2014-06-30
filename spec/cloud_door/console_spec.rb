require 'spec_helper'

def create_console
  console = CloudDoor::Console.new(CloudDoor::OneDrive)
  console.drive.storage.token.token_file       = './data/test_token'
  console.drive.storage.token.access_token     = 'token'
  console.drive.storage.token.refresh_token    = 'refresh'
  console.drive.storage.config.client_id       = '1234'
  console.drive.storage.config.client_secret   = 'abcd'
  console.drive.storage.config.redirect_url    = 'testurl'
  console.drive.storage.account.login_account  = 'test'
  console.drive.storage.account.login_password = 'pass1234'
  console.drive.storage.file_list.list_file    = './data/testlist'
  console
end

describe 'Console' do
  before(:each) do
    # $terminal is instance of Highline class
    $terminal.output = StringIO.new
  end

  describe 'config' do
    subject { console.config(show) }
    let(:console) { create_console }
    context 'input config' do
      let(:show) { false }
      it do
        subject
        config = console.drive.storage.config
        expect(config.client_id).to eq 'client'
        expect(config.client_secret).to eq 'secret'
        expect(config.redirect_url).to eq 'localhost'
        expects = 'update configuration success'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'show config' do
      let(:show) { true }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = <<EOF
OneDrive configuration are
  client_id    : 1234
  client_secret: abcd
  redirect_url : testurl
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'account' do
    subject { console.account(show) }
    let(:console) { create_console }
    context 'input account' do
      let(:show) { false }
      it do
        subject
        account = console.drive.storage.account
        expect(account.login_account).to eq 'account'
        expect(account.login_password).to eq 'password'
        expects = 'update account success'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'show account' do
      let(:show) { true }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = <<EOF
OneDrive account are
  login_account : test
  login_password: pass1234
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'auth' do
    subject { console.auth(default) }
    let(:console) { create_console }
    context 'success' do
      context 'use default account' do
        let(:default) { true }
        let(:posit) do
          {
            'file1'   => {'id' => 'file.1234', 'type' => 'file'},
            'folder1' => {'id' => 'folder.5678', 'type' => 'folder'}
          }
        end
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:isset_account?)
            .and_return(true)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:login)
            .and_return(true)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_user)
            .and_return({'name' => 'drive'})
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_current_dir)
            .and_return('/top')
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
            .with(true)
            .and_return(posit)
          subject
          expects = <<EOF
found defaulut account 'test'. use this account.
start a connection to the OneDrive. please wait a few seconds.
login success.
login as drive.

you have these files on '/top'.
[file  ] file1
[folder] folder1
EOF
          expect($terminal.output.string).to include(expects)
        end
      end
      context 'use input account' do
        let(:default) { false }
        let(:posit) do
          {
            'file1'   => {'id' => 'file.1234', 'type' => 'file'},
            'folder1' => {'id' => 'folder.5678', 'type' => 'folder'}
          }
        end
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:login)
            .and_return(true)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_user)
            .and_return({'name' => 'drive'})
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_current_dir)
            .and_return('/top')
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
            .with(true)
            .and_return(posit)
          subject
          expects = <<EOF
please enter the OneDrive account.
start a connection to the OneDrive. please wait a few seconds.
login success.
login as drive.

you have these files on '/top'.
[file  ] file1
[folder] folder1
EOF
          expect($terminal.output.string).to include(expects)
        end
      end
    end

    context 'fail' do
      context 'configuration not init' do
        let(:default) { false }
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:configuration_init?)
            .and_return(false)
          expect { subject }.to raise_error(SystemExit)
          expects = "config is not found. please execute './onedrive config' before."
          expect($terminal.output.string).to include(expects)
        end
      end
      context 'account not found' do
        let(:default) { true }
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:isset_account?)
            .and_return(false)
          expect { subject }.to raise_error(SystemExit)
          expects = "default account is not found. please execute './onedrive account' before."
          expect($terminal.output.string).to include(expects)
        end
      end
      context 'login fail' do
        let(:default) { false }
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:login)
            .and_return(false)
          subject
          expects = <<EOF
please enter the OneDrive account.
start a connection to the OneDrive. please wait a few seconds.
login fail.
EOF
          expect($terminal.output.string).to include(expects)
        end
      end
    end
  end

  describe 'ls' do
    subject { console.ls(file_name) }
    let(:console) { create_console }
    context 'have files' do
      let(:file_name) { nil }
      let(:posit) do
        {
          'file1'   => {'id' => 'file.1234', 'type' => 'file'},
          'folder1' => {'id' => 'folder.5678', 'type' => 'folder'}
        }
      end
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
          .with(true)
          .and_return(posit)
        subject
        expects = <<EOF
you have these files on '/top'.
[file  ] file1
[folder] folder1
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'not have file' do
      let(:file_name) { nil }
      let(:posit) { {} }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
          .with(true)
          .and_return(posit)
        subject
        expects = "you have no file on '/top'."
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file name input' do
      let(:file_name) { 'folder1' }
      let(:posit) do
        {
          'file2'   => {'id' => 'file.2345', 'type' => 'file'},
          'folder2' => {'id' => 'folder.6789', 'type' => 'folder'}
        }
      end
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
          .with(false)
          .and_return(posit)
        subject
        expects = <<EOF
you have these files on '/top/folder1'.
[file  ] file2
[folder] folder2
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'cd' do
    subject { console.cd(file_name) }
    let(:console) { create_console }
    context 'file_name not input' do
      let(:file_name) { nil }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = 'this command needs file name.'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'have files' do
      let(:file_name) { 'folder1' }
      let(:posit) do
        {
          'file2'   => {'id' => 'file.2345', 'type' => 'file'},
          'folder2' => {'id' => 'folder.6789', 'type' => 'folder'}
        }
      end
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(true)
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
          .with(true)
          .and_return(posit)
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_current_dir)
          .twice
          .and_return('/top')
        subject
        expects = <<EOF
move to '/top/folder1'.
you have these files on '/top/folder1'.
[file  ] file2
[folder] folder2
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'not have file' do
      let(:file_name) { 'folder1' }
      let(:posit) { {} }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(true)
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_files)
          .with(true)
          .and_return(posit)
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_current_dir)
          .twice
          .and_return('/top')
        subject
        expects = <<EOF
move to '/top/folder1'.
you have no file on '/top/folder1'.
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file not exists' do
      let(:file_name) { 'folder9' }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(false)
        expect { subject }.to raise_error(SystemExit)
        expects = "'/top/folder9' not exists in OneDrive"
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'info' do
    subject { console.info(file_name) }
    let(:console) { create_console }
    context 'file_name not input' do
      let(:file_name) { nil }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = 'this command needs file name.'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file exists' do
      let(:file_name) { 'file1' }
      let(:posit) do
        {
          'id'   => 'file.1234',
          'name' => 'file1'
        }
      end
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(true)
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_property)
          .and_return(posit)
        subject
        expects = <<EOF
information of '/top/file1'.
  id   : file.1234
  name : file1
EOF
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file not exists' do
      let(:file_name) { 'file9' }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(false)
        expect { subject }.to raise_error(SystemExit)
        expects = "'/top/file9' not exists in OneDrive"
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'pwd' do
    subject { console.pwd }
    let(:console) { create_console }
    let(:posit) { '/top' }
    it do
      expect_any_instance_of(CloudDoor::OneDrive).to receive(:show_current_dir)
        .and_return(posit)
      subject
      expects = '/top'
      expect($terminal.output.string).to include(expects)
    end
  end

  describe 'download' do
    subject { console.download(file_name) }
    let(:console) { create_console }
    context 'file_name not input' do
      let(:file_name) { nil }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = 'this command needs file name.'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file exists' do
      context 'not duplicate' do
        let(:file_name) { 'file1' }
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(true)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:download_file)
            .and_return(true)
          subject
          expects = "'file1' download success."
          expect($terminal.output.string).to include(expects)
        end
      end
      context 'duplicate' do
        let(:file_name) { 'file1' }
        before(:each) do
          open(file_name, 'wb') { |file| file << 'test' }
        end
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(true)
          expect { subject }.to raise_error(SystemExit)
          expects = "'file1' already exists in local."
          expect($terminal.output.string).to include(expects)
        end
        after(:each) do
          File.delete(file_name) if File.exist?(file_name)
        end
      end
    end
    context 'file not exists' do
      let(:file_name) { 'file9' }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(false)
        expect { subject }.to raise_error(SystemExit)
        expects = "'/top/file9' not exists in OneDrive."
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'upload' do
    subject { console.upload(file_name) }
    let(:console) { create_console }
    context 'file_name not input' do
      let(:file_name) { nil }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = 'this command needs file name.'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file exists' do
      context 'not duplicate' do
        let(:file_name) { 'file1' }
        before(:each) do
          open(file_name, 'wb') { |file| file << 'test' }
        end
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(false)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:upload_file)
            .and_return(true)
          subject
          expects = <<EOF
'/top/file1' upload success.
EOF
          expect($terminal.output.string).to include(expects)
        end
        after(:each) do
          File.delete(file_name) if File.exist?(file_name)
        end
      end
      context 'duplicate' do
        let(:file_name) { 'file1' }
        before(:each) do
          open(file_name, 'wb') { |file| file << 'test' }
        end
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(true)
          expect { subject }.to raise_error(SystemExit)
          expects = "'/top/file1' already exists in OneDrive."
          expect($terminal.output.string).to include(expects)
        end
        after(:each) do
          File.delete(file_name) if File.exist?(file_name)
        end
      end
      context'target is directory' do
        let(:file_name) { 'folder1' }
        before(:each) do
          Dir.mkdir(file_name)
        end
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(false)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:upload_file)
            .and_return(true)
          subject
          expects = <<EOF
'folder1' is a directory.
upload as 'folder1.zip'.

'/top/folder1.zip' upload success.
EOF
          expect($terminal.output.string).to include(expects)
        end
        after(:each) do
          Dir.rmdir(file_name) if Dir.exist?(file_name)
        end
      end
    end
    context 'file not exists' do
      let(:file_name) { 'file9' }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = "'file9' not exists in local."
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'rm' do
    subject { console.rm(file_name) }
    let(:console) { create_console }
    context 'file_name not input' do
      let(:file_name) { nil }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = 'this command needs file name.'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'file exists' do
      context 'target is file' do
        let(:file_name) { 'file1' }
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(true)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:has_file?)
            .and_return(false)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:delete_file)
            .and_return(true)
          subject
          expects = "'/top/file1' delete success."
          expect($terminal.output.string).to include(expects)
        end
      end
      context 'target is directory' do
        let(:file_name) { 'folder1' }
        it do
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
            .and_return(true)
          expect_any_instance_of(CloudDoor::OneDrive).to receive(:has_file?)
            .and_return(true)
          expect { subject }.to raise_error(SystemExit)
          expects = "'/top/folder1' has files."
          expect($terminal.output.string).to include(expects)
        end
      end
    end
    context 'file not exists' do
      let(:file_name) { 'file9' }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(false)
        expect { subject }.to raise_error(SystemExit)
        expects = "'/top/file9' not exists in OneDrive"
        expect($terminal.output.string).to include(expects)
      end
    end
  end

  describe 'mkdir' do
    subject { console.mkdir(mkdir_name) }
    let(:console) { create_console }
    context 'mkdir_name not input' do
      let(:mkdir_name) { nil }
      it do
        expect { subject }.to raise_error(SystemExit)
        expects = 'this command needs file name.'
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'folder not exists' do
      let(:mkdir_name) { 'folder1' }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(false)
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:make_directory)
          .and_return(true)
        subject
        expects = "make '/top/folder1' directory success."
        expect($terminal.output.string).to include(expects)
      end
    end
    context 'folder exists' do
      let(:mkdir_name) { 'folder1' }
      it do
        expect_any_instance_of(CloudDoor::OneDrive).to receive(:file_exists?)
          .and_return(true)
        expect { subject }.to raise_error(SystemExit)
        expects = "'/top/folder1' already exists in OneDrive."
        expect($terminal.output.string).to include(expects)
      end
    end
  end
end
