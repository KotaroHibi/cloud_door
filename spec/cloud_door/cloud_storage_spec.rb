require 'spec_helper'

# CloudStorage class is abstract class.
# then, test inherited subclass.
describe 'CloudStorage' do
  describe 'initialize' do
    subject { CloudDoor::CloudStorage.new }
    it { expect { subject }.to raise_error(CloudDoor::AbstractClassException) }
  end
end
