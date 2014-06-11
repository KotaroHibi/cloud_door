require 'spec_helper'

describe 'Token' do
  describe 'set_attributes' do
    let(:token) { Token.new }
    before (:each) { token.set_attributes({
      'token_type'    => 'bearer',
      'expires_in'    => 3600,
      'scope'         => 'wl.skydrive',
      'access_token'  => 'access_token',
      'refresh_token' => 'refresh_token',
      'user_id'       => 1,
      'dummy'         => 'dummy',
    })}
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
    before (:all) do
      File.delete('.test') if File.exists?('.test')
    end
    context 'success' do
      let(:token) { Fabricate.build(:token, :token_file => '.test') }
      it { is_expected.to be_truthy }
    end
    context 'fail' do
      let(:token) { Fabricate.build(:token, :token_file => nil) }
      it { is_expected.to be_falsey }
    end
    after (:all) do
      File.delete('.test') if File.exists?('.test')
    end
  end

  describe 'load_token' do
    subject { Token.load_token(token_file) }
    let(:token_file) { '.test' }
    context 'success' do
      let(:token_org) { Fabricate.build(:token) }
      before (:each) do
        open(token_file, 'wb') { |file| file << Marshal.dump(token_org) }
        @token = Token.load_token(token_file)
      end
      it { is_expected.to be_truthy }
      it { expect(@token.is_a?(Token)).to be_truthy }
      it {
        token_values     = get_instance_variable_values(@token)
        token_org_values = get_instance_variable_values(token_org)
        expect(token_values).to eq token_org_values
      }
    end
    context 'fail' do
      context 'file not exists' do
        it { is_expected.to be_nil }
      end
      context 'class is not Token' do
        before (:each) do
          open(token_file, 'wb') { |file| file << Marshal.dump('test') }
        end
        it { is_expected.to be_nil }
      end
    end
    after (:each) do
      File.delete(token_file) if File.exists?(token_file)
    end
  end
end
