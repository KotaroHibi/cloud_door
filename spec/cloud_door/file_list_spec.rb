require 'spec_helper'

def create_file_list
  file_list = FileList.new
  file_list.list_file = '.testlist'
  file_list
end

describe 'FileList' do
  describe 'load_list' do
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    subject { file_list.load_list }
    context 'list file not exists' do
      it { expect(subject).to be_true }
      it {
        subject
        expect(file_list.list).to eq []
      }
    end
    context 'list file is array' do
      let(:list) {
        [{'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}}]
      }
      before(:each) do
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { expect(subject).to be_true }
      it {
        subject
        expect(file_list.list).to eq list
      }
    end
    context 'list file is not array' do
      let(:list) {
        {'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}}
      }
      before(:each) do
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { expect(subject).to be_false }
      it {
        subject
        expect(file_list.list).to eq []
      }
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'add_list_top' do
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:items) { {'folder' => 'folder.1234'} }
    subject { file_list.add_list_top(items) }
    context 'success' do
      let(:added_list) {
        [{'id' => 'top', 'name' => 'top', 'items' => {'folder' => 'folder.1234'}}]
      }
      it { expect(subject).to be_true }
      it {
        subject
        file_list.load_list
        expect(file_list.list).to eq added_list
      }
    end
    context 'fail' do
      context 'items is nil' do
        let(:items) { nil }
        it { expect(subject).to be_false }
      end
      context 'items is not hash' do
        let(:items) { [] }
        it { expect(subject).to be_false }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'add_list' do
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) {
      [{'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}}]
    }
    let(:file_id) { 'folder.5678' }
    let(:file_name) { 'folder2' }
    let(:items) { {'test2' => 'file.5678'} }
    subject { file_list.add_list(file_id, file_name, items) }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      let(:added_list) { [
        {'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}},
        {'id' => 'folder.5678', 'name' => 'folder2', 'items' => {'test2' => 'file.5678'}},
      ] }
      it { expect(subject).to be_true }
      it {
        subject
        file_list.load_list
        expect(file_list.list).to eq added_list
      }
    end
    context 'fail' do
      context 'file_id is nil' do
        let(:file_id) { nil }
        it { expect(subject).to be_false }
      end
      context 'file_id is empty' do
        let(:file_id) { '' }
        it { expect(subject).to be_false }
      end
      context 'file_name is nil' do
        let(:file_name) { nil }
        it { expect(subject).to be_false }
      end
      context 'file_name is empty' do
        let(:file_name) { '' }
        it { expect(subject).to be_false }
      end
      context 'items is nil' do
        let(:items) { nil }
        it { expect(subject).to be_false }
      end
      context 'items is not hash' do
        let(:items) { [] }
        it { expect(subject).to be_false }
      end
      context 'list file is not array' do
        let(:list) {
          {'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}}
        }
        it { expect(subject).to be_false }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'remove_list' do
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) { [
      {'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}},
      {'id' => 'folder.5678', 'name' => 'folder2', 'items' => {'test2' => 'file.5678'}},
      {'id' => 'folder.3456', 'name' => 'folder3', 'items' => {'test3' => 'file.3456'}},
    ] }
    subject { file_list.remove_list(back) }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      context 'remove last 1' do
        let(:back) { 2 }
        it { expect(subject).to be_true }
        it {
          subject
          file_list.load_list
          expect(file_list.list).to eq list[0..1]
        }
      end
      context 'remove last 2' do
        let(:back) { 3 }
        it { expect(subject).to be_true }
        it {
          subject
          file_list.load_list
          expect(file_list.list).to eq list[0..0]
        }
      end
    end
    context 'success' do
      context 'remove all' do
        let(:back) { 4 }
        it { expect(subject).to be_false }
      end
      context 'list file is not array' do
        let(:list) {
          {'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}}
        }
        let(:back) { 1 }
        it { expect(subject).to be_false }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'delete_list' do
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) {
      [{'id' => 'folder.1234', 'name' => 'folder', 'items' => {'test' => 'file.1234'}}]
    }
    subject { file_list.delete_file }
    context 'file not exists' do
      it { expect(subject).to be_true }
      it {
        subject
        expect(File.exists?(file_list.list_file)).to be_false
      }
    end
    context 'file exists' do
      before(:each) do
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { expect(subject).to be_true }
      it {
        subject
        expect(File.exists?(file_list.list_file)).to be_false
      }
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end
end
