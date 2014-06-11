require 'spec_helper'

def create_file_list
  file_list = FileList.new
  file_list.list_file = '.testlist'
  file_list
end

describe 'FileList' do
  describe 'load_list' do
    subject { file_list.load_list }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    context 'list file not exists' do
      it { is_expected.to be_truthy }
      it {
        subject
        expect(file_list.list).to eq []
      }
    end
    context 'list file is array' do
      let(:list) {
        [{'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}}]
      }
      before(:each) do
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { is_expected.to be_truthy }
      it {
        subject
        expect(file_list.list).to eq list
      }
    end
    context 'list file is not array' do
      let(:list) {
        {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}}
      }
      before(:each) do
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { is_expected.to be_falsey }
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
    subject { file_list.add_list_top(items) }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:items) { {'folder' => 'folder.1234'} }
    before (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
    context 'success' do
      let(:added_list) {
        [{'id' => 'top', 'name' => 'top', 'items' => {'folder' => 'folder.1234'}}]
      }
      it { is_expected.to be_truthy }
      it {
        subject
        file_list.load_list
        expect(file_list.list).to eq added_list
      }
    end
    context 'fail' do
      context 'items is nil' do
        let(:items) { nil }
        it { is_expected.to be_falsey }
      end
      context 'items is not hash' do
        let(:items) { [] }
        it { is_expected.to be_falsey }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'add_list' do
    subject { file_list.add_list(items, file_id, file_name) }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) {
      [{'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}}]
    }
    let(:file_id) { 'folder.5678' }
    let(:file_name) { 'folder1' }
    let(:items) { {'test2' => 'file.5678'} }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      let(:added_list) { [
        {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
        {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
      ] }
      it { is_expected.to be_truthy }
      it {
        subject
        file_list.load_list
        expect(file_list.list).to eq added_list
      }
    end
    context 'fail' do
      context 'file_id is nil' do
        let(:file_id) { nil }
        it { is_expected.to be_falsey }
      end
      context 'file_id is empty' do
        let(:file_id) { '' }
        it { is_expected.to be_falsey }
      end
      context 'file_name is nil' do
        let(:file_name) { nil }
        it { is_expected.to be_falsey }
      end
      context 'file_name is empty' do
        let(:file_name) { '' }
        it { is_expected.to be_falsey }
      end
      context 'items is nil' do
        let(:items) { nil }
        it { is_expected.to be_falsey }
      end
      context 'items is not hash' do
        let(:items) { [] }
        it { is_expected.to be_falsey }
      end
      context 'list file is not array' do
        let(:list) {
          {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}}
        }
        it { is_expected.to be_falsey }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'update_list' do
    subject { file_list.update_list(items) }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) { [
      {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
      {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
      {'id' => 'folder.3456', 'name' => 'folder2', 'items' => {'test3' => 'file.3456'}},
    ] }
    let(:items) { {'test4' => 'file.7890'} }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      let(:updated_list) { [
        {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
        {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
        {'id' => 'folder.3456', 'name' => 'folder2', 'items' => {'test4' => 'file.7890'}},
      ] }
      it { is_expected.to be_truthy }
      it {
        subject
        file_list.load_list
        expect(file_list.list).to eq updated_list
      }
    end
    context 'fail' do
      context 'items is nil' do
        let(:items) { nil }
        it { is_expected.to be_falsey }
      end
      context 'items is not hash' do
        let(:items) { [] }
        it { is_expected.to be_falsey }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'remove_list' do
    subject { file_list.remove_list(back) }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) { [
      {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
      {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
      {'id' => 'folder.3456', 'name' => 'folder2', 'items' => {'test3' => 'file.3456'}},
    ] }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'success' do
      context 'remove last 1' do
        let(:back) { 2 }
        it { is_expected.to be_truthy }
        it {
          subject
          file_list.load_list
          expect(file_list.list).to eq list[0..1]
        }
      end
      context 'remove last 2' do
        let(:back) { 3 }
        it { is_expected.to be_truthy }
        it {
          subject
          file_list.load_list
          expect(file_list.list).to eq list[0..0]
        }
      end
    end
    context 'fail' do
      context 'remove all' do
        let(:back) { 4 }
        it { is_expected.to be_falsey }
      end
      context 'list file is not array' do
        let(:list) {
          {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}}
        }
        let(:back) { 1 }
        it { is_expected.to be_falsey }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'delete_list' do
    subject { file_list.delete_file }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) {
      [{'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}}]
    }
    context 'file not exists' do
      it { is_expected.to be_truthy }
      it {
        subject
        expect(File.exists?(file_list.list_file)).to be_falsey
      }
    end
    context 'file exists' do
      before(:each) do
        open(list_file, 'wb') { |file| file << Marshal.dump(list) }
      end
      it { is_expected.to be_truthy }
      it {
        subject
        expect(File.exists?(file_list.list_file)).to be_falsey
      }
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'get_parent_id' do
    subject { file_list.get_parent_id }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) { [
      {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
      {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
      {'id' => 'folder.3456', 'name' => 'folder2', 'items' => {'test3' => 'file.3456'}},
    ] }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    it { is_expected.to eq 'folder.3456' }
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'get_current_dir' do
    subject { file_list.get_current_dir }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'top' do
      let(:list) { [
        {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
      ] }
      it { is_expected.to eq '/top' }
    end
    context 'directory' do
      let(:list) { [
        {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
        {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
        {'id' => 'folder.3456', 'name' => 'folder2', 'items' => {'test3' => 'file.3456'}},
      ] }
      it { is_expected.to eq '/top/folder1/folder2' }
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
  end

  describe 'convert_name_to_id' do
    subject { file_list.convert_name_to_id(mode, file_name) }
    let(:file_list) { create_file_list }
    let(:list_file) { '.testlist' }
    let(:list) { [
      {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
      {'id' => 'folder.5678', 'name' => 'folder1', 'items' => {'test2' => 'file.5678'}},
      {'id' => 'folder.3456', 'name' => 'folder2', 'items' => {'test3' => 'file.3456'}},
    ] }
    before(:each) do
      open(list_file, 'wb') { |file| file << Marshal.dump(list) }
    end
    context 'mode == current' do
      let(:mode) { 'current' }
      let(:file_name) { nil }
      context 'top' do
        let(:list) { [
          {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
        ] }
        it { is_expected.to be_nil }
      end
      context 'directory' do
        it { is_expected.to eq 'folder.3456' }
      end
    end
    context 'mode == parent' do
      let(:mode) { 'parent' }
      context 'top' do
        let(:file_name) { '../' }
        let(:list) { [
          {'id' => 'top', 'name' => 'top', 'items' => {'test' => 'file.1234'}},
        ] }
        it { is_expected.to be_falsey }
      end
      context 'back to folder' do
        let(:file_name) { '../' }
        it { is_expected.to eq 'folder.5678' }
      end
      context 'back to top' do
        let(:file_name) { '../../' }
        it { is_expected.to be_nil }
      end
    end
    after (:each) do
      File.delete(list_file) if File.exists?(list_file)
    end
    context 'mode == target' do
      let(:mode) { 'target' }
      let(:file_name) { 'test3' }
      context 'target found' do
        it { is_expected.to eq 'file.3456' }
      end
      context 'target not found' do
        let(:file_name) { 'test4' }
        it { is_expected.to be_falsey }
      end
      context 'list is empty' do
        let(:list) { [] }
        it { is_expected.to be_falsey }
      end
      context 'items is empty' do
        let(:list) { [
          {'id' => 'top', 'name' => 'top', 'items' => {}},
        ] }
        it { is_expected.to be_falsey }
      end
    end
  end
end
