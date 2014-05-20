require 'spec_helper'

describe 'Account' do
  let(:account_file) { '.test.yml' }
  describe 'load_yaml' do
    before (:all) do
      accounts = {
        'onedrive' => {'login_account' => 'login@onedrive.com', 'login_password' => 'onedrive'},
        'dropbox' => {'login_account' => 'login@dropbox.com', 'login_password' => 'dropbox'},
      }
      open('.test.yml', 'wb') { |file| YAML.dump(accounts, file) }
    end
    before (:each) { account.load_yaml }
    context 'onedrive' do
      let(:account) { Fabricate.build(:account, :storage => 'onedrive', :file => account_file) }
      it { expect(account.login_account).to eq 'login@onedrive.com' }
      it { expect(account.login_password).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:account) { Fabricate.build(:account, :storage => 'dropbox', :file => account_file) }
      it { expect(account.login_account).to eq 'login@dropbox.com' }
      it { expect(account.login_password).to eq 'dropbox' }
    end
    after (:all) do
      File.delete('.test.yml') if File.exists?('.test.yml')
    end
  end

  describe 'update_yaml' do
    before (:each) do
      File.delete(account_file) if File.exists?(account_file)
      account.update_yaml(update_params)
    end
    context 'onedrive' do
      let(:account) { Fabricate.build(:account, :storage => 'onedrive', :file => account_file) }
      let(:update_params) { {'login_account' => 'login@onedrive.com', 'login_password' => 'onedrive'} }
      it { expect(File.exists?(account_file)).to be_true }
      it { expect(YAML.load_file(account_file)['onedrive']['login_account']).to eq 'login@onedrive.com' }
      it { expect(YAML.load_file(account_file)['onedrive']['login_password']).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:account) { Fabricate.build(:account, :storage => 'dropbox', :file => account_file) }
      let(:update_params) { {'login_account' => 'login@dropbox.com', 'login_password' => 'dropbox'} }
      it { expect(File.exists?(account_file)).to be_true }
      it { expect(YAML.load_file(account_file)['dropbox']['login_account']).to eq 'login@dropbox.com' }
      it { expect(YAML.load_file(account_file)['dropbox']['login_password']).to eq 'dropbox' }
    end
    after (:each) do
      File.delete(account_file) if File.exists?(account_file)
    end
  end
end
