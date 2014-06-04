class FileList
  attr_accessor :list_file
  attr_reader :list

  LIST_FILE = 'listdata'

  def initialize
    @list_file = LIST_FILE
    @list      = []
  end

  def load_list
    list = []
    if File.exists?(@list_file)
      marshal = File.open(@list_file).read
      list = Marshal.load(marshal)
      return false unless list.is_a?(Array)
    end
    @list = list
    true
  end

  def add_list_top(items)
    return false if (items.nil? || !items.is_a?(Hash))
    @list << {'id' => 'top', 'name' => 'top', 'items' => items}
    write_file
  end

  def add_list(file_id, file_name, items)
    return false if (file_id.nil? || file_id.empty?)
    return false if (file_name.nil? || file_name.empty?)
    return false if (items.nil? || !items.is_a?(Hash))
    return false if load_list == false
    @list << {'id' => file_id, 'name' => file_name, 'items' => items}
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
    begin
      File.delete(@list_file) if File.exists?(@list_file)
      true
    rescue
      false
    end
  end

  private
  def write_file
    begin
      marshal = Marshal.dump(@list)
      open(@list_file, 'wb') { |file| file << marshal }
      true
    rescue
      false
    end
  end
end
