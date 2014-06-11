require 'spec_helper'

describe 'CloudConfig' do
  describe 'load_yaml' do
    config_file = '.test.yml'
    before (:all) do
      configs = {
        'onedrive' => {'client_id' => '1234', 'client_secret' => 'abcd', 'redirect_url' => 'onedrive'},
        'dropbox' => {'client_id' => '5678', 'client_secret' => 'efgh', 'redirect_url' => 'dropbox'},
      }
      open('.test.yml', 'wb') { |file| YAML.dump(configs, file) }
    end
    before (:each) { config.load_yaml }
    context 'onedrive' do
      let(:config) { Fabricate.build(:cloud_config, :storage => 'onedrive', :file => config_file) }
      it { expect(config.client_id).to eq '1234' }
      it { expect(config.client_secret).to eq 'abcd' }
      it { expect(config.redirect_url).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:config) { Fabricate.build(:cloud_config, :storage => 'dropbox', :file => config_file) }
      it { expect(config.client_id).to eq '5678' }
      it { expect(config.client_secret).to eq 'efgh' }
      it { expect(config.redirect_url).to eq 'dropbox' }
    end
    after (:all) do
      File.delete('.test.yml') if File.exists?('.test.yml')
    end
  end

  describe 'update_yaml' do
    config_file = '.test.yml'
    before (:each) do
      File.delete(config_file) if File.exists?(config_file)
      account.update_yaml(update_params)
    end
    context 'onedrive' do
      let(:account) { Fabricate.build(:cloud_config, :storage => 'onedrive', :file => config_file) }
      let(:update_params) { {'client_id' => '1234', 'client_secret' => 'abcd', 'redirect_url' => 'onedrive'} }
      it { expect(File.exists?(config_file)).to be_truthy }
      it { expect(YAML.load_file(config_file)['onedrive']['client_id']).to eq '1234' }
      it { expect(YAML.load_file(config_file)['onedrive']['client_secret']).to eq 'abcd' }
      it { expect(YAML.load_file(config_file)['onedrive']['redirect_url']).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:account) { Fabricate.build(:cloud_config, :storage => 'dropbox', :file => config_file) }
      let(:update_params) { {'client_id' => '5678', 'client_secret' => 'efgh', 'redirect_url' => 'dropbox'} }
      it { expect(File.exists?(config_file)).to be_truthy }
      it { expect(YAML.load_file(config_file)['dropbox']['client_id']).to eq '5678' }
      it { expect(YAML.load_file(config_file)['dropbox']['client_secret']).to eq 'efgh' }
      it { expect(YAML.load_file(config_file)['dropbox']['redirect_url']).to eq 'dropbox' }
    end
    after (:each) do
      File.delete(config_file) if File.exists?(config_file)
    end
  end

  describe 'is_init?' do
    subject { config.is_init? }
    let(:config) { Fabricate.build(:cloud_config) }
    context 'initialized' do
      before (:each) do
        config.client_id     = '1234'
        config.client_secret = 'abcd'
        config.redirect_url  = 'onedrive'
      end
      it { is_expected.to be_truthy }
    end
    context 'not initialized' do
      it { is_expected.to be_falsey }
    end
  end
end
