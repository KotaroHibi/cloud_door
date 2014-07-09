require 'spec_helper'

describe 'Config' do
  describe 'load_yaml' do
    let(:config_file) { './data/test.yml' }
    before(:all) do
      configs = {
        'onedrive' => {
          'client_id'     => '1234',
          'client_secret' => 'abcd',
          'redirect_url'  => 'onedrive'
        },
        'dropbox' => {
          'client_id'     => '5678',
          'client_secret' => 'efgh',
          'redirect_url'  => 'dropbox'
        }
      }
      open('./data/test.yml', 'wb') { |file| YAML.dump(configs, file) }
    end
    before(:each) { config.load_yaml }
    context 'onedrive' do
      let(:config) { Fabricate.build(:config, storage: 'onedrive', file: config_file) }
      it { expect(config.client_id).to eq '1234' }
      it { expect(config.client_secret).to eq 'abcd' }
      it { expect(config.redirect_url).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:config) { Fabricate.build(:config, storage: 'dropbox', file: config_file) }
      it { expect(config.client_id).to eq '5678' }
      it { expect(config.client_secret).to eq 'efgh' }
      it { expect(config.redirect_url).to eq 'dropbox' }
    end
    after(:all) do
      File.delete('./data/test.yml') if File.exist?('./data/test.yml')
    end
  end

  describe 'update_yaml' do
    let(:config_file) { './data/test.yml' }
    before(:each) do
      File.delete(config_file) if File.exist?(config_file)
      account.update_yaml(update_params)
    end
    context 'onedrive' do
      let(:account) { Fabricate.build(:config, storage: 'onedrive', file: config_file) }
      let(:update_params) do
        {
          'client_id'     => '1234',
          'client_secret' => 'abcd',
          'redirect_url'  => 'onedrive'
        }
      end
      let(:load_file) { YAML.load_file(config_file)['onedrive'] }
      it { expect(File.exist?(config_file)).to be_truthy }
      it { expect(load_file['client_id']).to eq '1234' }
      it { expect(load_file['client_secret']).to eq 'abcd' }
      it { expect(load_file['redirect_url']).to eq 'onedrive' }
    end
    context 'dropbox' do
      let(:account) { Fabricate.build(:config, storage: 'dropbox', file: config_file) }
      let(:update_params) do
        {
          'client_id'     => '5678',
          'client_secret' => 'efgh',
          'redirect_url'  => 'dropbox'
        }
      end
      let(:load_file) { YAML.load_file(config_file)['dropbox'] }
      it { expect(File.exist?(config_file)).to be_truthy }
      it { expect(load_file['client_id']).to eq '5678' }
      it { expect(load_file['client_secret']).to eq 'efgh' }
      it { expect(load_file['redirect_url']).to eq 'dropbox' }
    end
    after(:each) do
      File.delete(config_file) if File.exist?(config_file)
    end
  end

  describe 'init?' do
    subject { config.init? }
    let(:config) { Fabricate.build(:config) }
    context 'initialized' do
      before(:each) do
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
