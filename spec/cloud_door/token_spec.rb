require 'spec_helper'

describe 'Token' do
  describe 'set_attributes' do
    let(:token) { CloudDoor::Token.new('test_token', './data/') }
    let(:attributes) do
      {
        'token_type'    => 'bearer',
        'expires_in'    => 3600,
        'scope'         => 'wl.skydrive',
        'access_token'  => 'access_token',
        'refresh_token' => 'refresh_token',
        'user_id'       => 1,
        'dummy'         => 'dummy'
      }
    end
    before(:each) do
      token.set_attributes(attributes)
    end
    it { expect(token.token_type).to eq 'bearer' }
    it { expect(token.expires_in).to eq 3600 }
    it { expect(token.scope).to eq 'wl.skydrive' }
    it { expect(token.access_token).to eq 'access_token' }
    it { expect(token.refresh_token).to eq 'refresh_token' }
    it { expect(token.user_id).to eq 1 }
    it { expect(token.instance_variable_defined?(:@dummy)).to be_falsey }
  end

  describe 'write_token' do
    subject { token.write_token }
    let(:token) { Fabricate.build(:token, token_file: './data/test_token') }
    before(:all) do
      File.delete('./data/test_token') if File.exist?('./data/test_token')
    end
    context 'success' do
      it { is_expected.to be_truthy }
    end
    context 'fail' do
      before(:each) do
        token.token_file = nil
      end
      it { is_expected.to be_falsey }
    end
    after(:all) do
      File.delete('../data/test_token') if File.exist?('./data/test_token')
    end
  end

  describe 'load_token' do
    subject { CloudDoor::Token.load_token('test_token', './data/') }
    let(:token_file) { './data/test_token' }
    context 'success' do
      let(:token_org) { Fabricate.build(:token, token_file: 'test_token') }
      before(:each) do
        open(token_file, 'wb') { |file| file << Marshal.dump(token_org) }
        @token = CloudDoor::Token.load_token('test_token', './data/')
      end
      it { is_expected.to be_truthy }
      it { expect(@token.is_a?(CloudDoor::Token)).to be_truthy }
      it do
        token_values     = get_instance_variable_values(@token)
        token_org_values = get_instance_variable_values(token_org)
        expect(token_values).to eq token_org_values
      end
    end
    context 'fail' do
      context 'file not exists' do
        it { is_expected.to be_nil }
      end
      context 'class is not Token' do
        before(:each) do
          open(token_file, 'wb') { |file| file << Marshal.dump('test') }
        end
        it { is_expected.to be_nil }
      end
    end
    after(:each) do
      File.delete(token_file) if File.exist?(token_file)
    end
  end
end
