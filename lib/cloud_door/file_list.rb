module CloudDoor
  class FileList
    attr_accessor :list_file, :list_name
    attr_reader :list

    def initialize(list_name, data_path, id = nil)
      @list_name = list_name
      @data_path = data_path
      if (id.nil?)
        @list_file = @data_path + @list_name
      else
        list_dir = @data_path + "#{id}"
        unless File.exists?(list_dir)
          Dir.mkdir(list_dir)
        end
        @list_file = "#{list_dir}/#{@list_name}"
      end
      @list = nil
    end

    def set_locate(id)
      list_dir = @data_path + "#{id}"
      unless File.exists?(list_dir)
        Dir.mkdir(list_dir)
      end
      @list_file = "#{list_dir}/#{@list_name}"
    end

    def load_list
      list = []
      if File.exist?(@list_file)
        marshal = File.open(@list_file).read
        list = Marshal.load(marshal)
        return false unless list.is_a?(Array)
      end
      @list = list
      true
    end

    def write_file_list(items, file_id = '', file_name = '')
      return false if load_list == false
      if @list.empty?
        add_list_top(items)
      elsif file_name =~ CloudStorage::PARENT_DIR_PAT
        back = file_name.scan(CloudStorage::PARENT_DIR_PAT).size + 1
        remove_list(back)
      else
        if file_name.nil? || file_name.empty?
          update_list(items)
        else
          add_list(items, file_id, file_name)
        end
      end
    end

    def add_list_top(items)
      return false if items.nil? || !items.is_a?(Hash)
      @list = []
      @list << {'id' => 'top', 'name' => 'top', 'items' => items}
      write_file
    end

    def add_list(items, file_id, file_name)
      return false if items.nil? || !items.is_a?(Hash)
      return false if file_id.nil? || file_id.empty?
      return false if file_name.nil? || file_name.empty?
      return false if load_list == false
      @list << {'id' => file_id, 'name' => file_name, 'items' => items}
      write_file
    end

    def update_list(items)
      return false if items.nil? || !items.is_a?(Hash)
      return false if load_list == false
      last_node = @list[-1]
      @list[-1] = {'id' => last_node['id'], 'name' => last_node['name'], 'items' => items}
      write_file
    end

    def remove_list(back)
      return false if load_list == false
      size = @list.size
      return false if back > size
      last = size - back
      @list = @list[0..last]
      write_file
    end

    def delete_file
      File.delete(@list_file) if File.exist?(@list_file)
      true
    rescue
      false
    end

    def pull_parent_id
      convert_name_to_id('current')
    end

    def pull_current_dir
      return false if load_list == false
      return '/top' if @list.size < 2
      files = []
      @list.each { |part| files << part['name'] unless part['name'].nil? }
      '/' + files.join('/')
    end

    def pull_file_properties(file_name)
      if @list.nil?
        return false if load_list == false
      end
      return false if @list.empty?
      items = @list.last['items']
      return false if items.empty? || !items.key?(file_name)
      items[file_name]
    end

    def convert_name_to_id(mode, file_name = '')
      return false if load_list == false
      return false unless %w(current parent target).include?(mode)
      send("convert_#{mode}_id", file_name)
    end

    def top?(file_name)
      back = (file_name.scan(CloudStorage::PARENT_DIR_PAT).size) + 1
      @list.count < back
    end

    private

    def write_file
      marshal = Marshal.dump(@list)
      open(@list_file, 'wb') { |file| file << marshal }
      true
    rescue
      false
    end

    def convert_current_id(*)
      if @list.count < 2
        nil
      else
        @list.last['id']
      end
    end

    def convert_parent_id(file_name)
      back = (file_name.scan(CloudStorage::PARENT_DIR_PAT).size) + 1
      return false if @list.size < back
      last = @list.size - back
      if last == 0
        nil
      else
        @list[list.size - back]['id']
      end
    end

    def convert_target_id(file_name)
      properties = pull_file_properties(file_name)
      return false unless properties
      properties['id']
    end
  end
end
