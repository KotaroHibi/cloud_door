require 'spec_helper'

describe 'Account' do
  describe 'isset_account?' do
    subject { account.isset_account? }
    let(:account) { Fabricate.build(:account, storage: 'onedrive', file: account_file) }
    context 'account & password setted' do
      before(:each) do
        account.login_account  = 'login@onedrive.com'
        account.login_password = 'onedrive.com'
      end
      it { is_expected.to be_truthy }
    end
    context 'account not setted' do
      before(:each) do
        account.login_account  = 'login@onedrive.com'
        account.login_password = ''
      end
      it { is_expected.to be_falsey }
    end
    context 'password not setted' do
      before(:each) do
        account.login_account  = ''
        account.login_password = 'onedrive.com'
      end
      it { is_expected.to be_falsey }
    end
  end

  let(:account_file) { '.test.yml' }
  describe 'load_yaml' do
    before(:all) do
      accounts = {
        'onedrive' => {
          'login_account'  => 'login@onedrive.com',
          'login_password' => 'onedrive'
        },
        'dropbox' => {
          'login_account'  => 'login@dropbox.com',
          'login_password' => 'dropbox'
        }
      }
      open('.test.yml', 'wb') { |file| YAML.dump(accounts, file) }
    end
    before(:each) { account.load_yaml }
    context 'onedrive' do
      let(:account) { Fabricate.build(:account, storage: 'onedrive', file: account_file) }
      it { expect(account.login_account).to eq 'login@onedrive.com' }
      it { expect(account.login_password).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:account) { Fabricate.build(:account, storage: 'dropbox', file: account_file) }
      it { expect(account.login_account).to eq 'login@dropbox.com' }
      it { expect(account.login_password).to eq 'dropbox' }
    end
    after(:all) do
      File.delete('.test.yml') if File.exist?('.test.yml')
    end
  end

  describe 'update_yaml' do
    before(:each) do
      File.delete(account_file) if File.exist?(account_file)
      account.update_yaml(update_params)
    end
    context 'onedrive' do
      let(:account) { Fabricate.build(:account, storage: 'onedrive', file: account_file) }
      let(:update_params) do
        {
          'login_account'  => 'login@onedrive.com',
          'login_password' => 'onedrive'
        }
      end
      let(:load_file) { YAML.load_file(account_file)['onedrive'] }
      it { expect(File.exist?(account_file)).to be_truthy }
      it { expect(load_file['login_account']).to eq 'login@onedrive.com' }
      it { expect(load_file['login_password']).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:account) { Fabricate.build(:account, storage: 'dropbox', file: account_file) }
      let(:update_params) do
        {
          'login_account'  => 'login@dropbox.com',
          'login_password' => 'dropbox'
        }
      end
      let(:load_file) { YAML.load_file(account_file)['dropbox'] }
      it { expect(File.exist?(account_file)).to be_truthy }
      it { expect(load_file['login_account']).to eq 'login@dropbox.com' }
      it { expect(load_file['login_password']).to eq 'dropbox' }
    end
    after(:each) do
      File.delete(account_file) if File.exist?(account_file)
    end
  end
end
