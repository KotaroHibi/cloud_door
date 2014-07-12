require 'highline/import'
require 'cloud_door'

module CloudDoor
  class Console
    attr_accessor :drive
    attr_reader :storage_name

    def initialize(drive, session_id = nil)
      @drive = CloudDoor.new(drive, session_id)
      @storage_name = @drive.show_storage_name
    end

    def config(show = false)
      if show
        show_configuration(@drive.show_configuration)
        exit
      end
      configs = ask_configuration
      result  = @drive.update_configuration(configs)
      show_result_message(result, 'update configuration')
    end

    def account(show = false)
      if show
        show_account(@drive.show_account)
        exit
      end
      accounts = ask_account
      result   = @drive.update_account(accounts)
      show_result_message(result, 'update account')
    end

    def login(default = false)
      unless @drive.configuration_init?
        say(make_message(:not_configuration, @storage_name.downcase))
        exit
      end
      exit unless agree(make_message(:agree_access, @storage_name))
      account = login_set_account(default)
      say(make_message(:start_connection, @storage_name))
      if @drive.login(account['login_account'], account['login_password'])
        user      = @drive.show_user
        user_name = user['name'] || user['display_name']
        say(make_message(:result_success, 'login'))
        say(make_message(:login_as, user_name))
        say("\n")
        pwd  = @drive.show_current_directory
        list = @drive.show_files
        show_file_list(pwd, list)
      else
        say(make_message(:result_fail, 'login'))
      end
    rescue => e
      show_exception(e)
    end

    def ls(file_name)
      @drive.load_token
      fullname = make_fullname(file_name)
      if !file_name.nil? && !file_name.empty?
        unless @drive.file_exist?(file_name)
          say(make_message(:file_not_exists, fullname, @storage_name))
          exit
        end
      end
      list = @drive.show_files(file_name)
      show_file_list(fullname, list)
    rescue => e
      show_exception(e)
    end

    def cd(file_name)
      if (file_name.nil? || file_name.empty?)
        say(make_message(:wrong_parameter, 'file name'))
        exit
      end
      @drive.load_token
      fullname = make_fullname(file_name)
      unless @drive.file_exist?(file_name)
        say(make_message(:file_not_exists, fullname, @storage_name))
        exit
      end
      say(make_message(:move_to, fullname))
      list = @drive.change_directory(file_name)
      show_file_list(fullname, list)
    rescue => e
      show_exception(e)
    end

    def info(file_name)
      if (file_name.nil? || file_name.empty?)
        say(make_message(:wrong_parameter, 'file name'))
        exit
      end
      @drive.load_token
      fullname = make_fullname(file_name)
      unless @drive.file_exist?(file_name)
        say(make_message(:file_not_exists, fullname, @storage_name))
        exit
      end
      info = @drive.show_property(file_name)
      unless (info.empty?)
        say(make_message(:show_information, fullname))
        max = info.max { |a, b| a[0].length <=> b[0].length }
        max_len = max[0].length
        info.each do |key, value|
          say("  #{key.ljust(max_len)} : #{value}")
        end
      end
    rescue => e
      show_exception(e)
    end

    def pwd
      @drive.load_token
      say(@drive.show_current_directory)
    end

    def download(file_name)
      if (file_name.nil? || file_name.empty?)
        say(make_message(:wrong_parameter, 'file name'))
        exit
      end
      @drive.load_token
      fullname = make_fullname(file_name)
      unless @drive.file_exist?(file_name)
        say(make_message(:file_not_exists, fullname, @storage_name))
        exit
      end
      if File.exist?(file_name)
        say(make_message(:same_file_exist, file_name, 'local'))
        exit unless agree(make_message(:agree_overwrite, file_name))
      end
      result = @drive.download_file(file_name)
      show_result_message(result, "'#{file_name}' download")
    rescue => e
      show_exception(e)
    end

    def upload(file_name)
      if (file_name.nil? || file_name.empty?)
        say(make_message(:wrong_parameter, 'file name'))
        exit
      end
      @drive.load_token
      unless File.exists?(file_name)
        say(make_message(:file_not_exists, file_name, 'local'))
        exit
      end
      if File.directory?(file_name)
        say(make_message(:is_directory, file_name))
        say(make_message(:compress_to, file_name))
        say("\n")
      end
      up_file  = @drive.assign_upload_file_name(file_name)
      fullname = make_fullname(up_file)
      if @drive.file_exist?(up_file)
        say(make_message(:same_file_exist, fullname, @storage_name))
        exit unless agree(make_message(:agree_overwrite, fullname))
      end
      result = @drive.upload_file(file_name)
      show_result_message(result, "'#{fullname}' upload")
    rescue => e
      show_exception(e)
    end

    def rm(file_name)
      if (file_name.nil? || file_name.empty?)
        say(make_message(:wrong_parameter, 'file name'))
        exit
      end
      @drive.load_token
      fullname = make_fullname(file_name)
      exit unless agree(make_message(:agree_delete, fullname))
      unless @drive.file_exist?(file_name)
        say(make_message(:file_not_exists, fullname, @storage_name))
        exit
      end
      if @drive.has_file?(file_name)
        say(make_message(:has_files, fullname))
        # exit unless agree("Do you want to delete these files (Y/N)?")
        exit
      end
      result = @drive.delete_file(file_name)
      show_result_message(result, "'#{fullname}' delete")
    rescue => e
      show_exception(e)
    end

    def mkdir(mkdir_name)
      if (mkdir_name.nil? || mkdir_name.empty?)
        say(make_message(:wrong_parameter, 'file name'))
        exit
      end
      @drive.load_token
      fullname = make_fullname(mkdir_name)
      if @drive.file_exist?(mkdir_name)
        say(make_message(:same_file_exist, fullname, @storage_name))
        exit
      end
      result = @drive.make_directory(mkdir_name)
      show_result_message(result, "make '#{fullname}' directory")
    rescue => e
      show_exception(e)
    end

    private

    def make_message(type, *args)
      messages = {
        show_configuration: "#{args[0]} configuration are",
        show_account:       "#{args[0]} account are",
        ask_configuration:  "please enter the #{args[0]} configuration.",
        ask_account:        "please enter the #{args[0]} account.",
        not_configuration:  "config is not found. please execute './#{args[0]} config' before.",
        account_found:      "found defaulut account '#{args[0]}'. use this account.",
        account_not_found:  "default account is not found. please execute './#{args[0]} account' before.",
        start_connection:   "start a connection to the #{args[0]}. please wait a few seconds.",
        login_as:           "login as #{args[0]}.",
        show_files:         "you have these files on '#{args[0]}'.",
        show_no_file:       "you have no file on '#{args[0]}'.",
        show_information:   "information of '#{args[0]}'.",
        move_to:            "move to '#{args[0]}'.",
        is_directory:       "'#{args[0]}' is a directory.",
        compress_to:        "upload as '#{args[0]}.zip'.",
        has_files:          "'#{args[0]}' has files.",
        wrong_parameter:    "this command needs #{args[0]}.",
        file_not_exists:    "'#{args[0]}' not exists in #{args[1]}.",
        same_file_exist:    "'#{args[0]}' already exists in #{args[1]}.",
        agree_access:       "do you want to allow access to the #{args[0]} from this system(Y/N)?",
        agree_overwrite:    "do you want to overwrite '#{args[0]}' (Y/N)?",
        agree_delete:       "do you want to delete '#{args[0]}' (Y/N)?",
        result_success:     "#{args[0]} success.",
        result_fail:        "#{args[0]} fail.",
        result_exception:   "command fail.",
        login_fail:         "login fail.",
        unauthorized:       "please execute #{args[0]} auth' command."
      }
      if messages.key?(type)
        messages[type]
      end
    end

    def make_fullname(file_name)
      pwd = @drive.show_current_directory
      if file_name.nil? || file_name.empty?
        pwd
      else
        "#{pwd}/#{file_name}"
      end
    end

    def show_configuration(config)
      say(make_message(:show_configuration, @storage_name))
      say("  client_id    : #{config.client_id}\n")
      say("  client_secret: #{config.client_secret}\n")
      say("  redirect_url : #{config.redirect_url}\n")
    end

    def ask_configuration
      say(make_message(:ask_configuration, @storage_name))
      configs = {}
      configs['client_id']      = ask('client_id     : ')
      configs['client_secret']  = ask('client_secret : ')
      configs['redirect_url']   = ask('redirect_url  : ')
      configs.each { |key, val| configs[key] = val.to_s }
    end

    def show_account(account)
      say(make_message(:show_account, @storage_name))
      say("  login_account : #{account.login_account}\n")
      say("  login_password: #{account.login_password}\n")
    end

    def ask_account
      say(make_message(:ask_account, @storage_name))
      accounts = {}
      accounts['login_account']  = ask('login_account : ')
      accounts['login_password'] = ask('login_password: ') { |q| q.echo = '*' }
      accounts.each { |key, val| accounts[key] = val.to_s }
    end

    def login_set_account(default)
      account = Hash.new
      if default
        if @drive.isset_account?
          default_account = @drive.show_account
          account['login_account']  = default_account.login_account
          account['login_password'] = default_account.login_password
          say(make_message(:account_found, account['login_account']))
        else
          say(make_message(:account_not_found, @storage_name.downcase))
          exit
        end
      else
        say(make_message(:ask_account, @storage_name))
        login_account  = ask('login_account : ')
        login_password = ask('login_password: ') { |q| q.echo = '*' }
        account['login_account']  = login_account
        account['login_password'] = login_password
      end
      account
    end

    def show_file_list(pwd, list)
      if list.count > 0
        say(make_message(:show_files, pwd))
        list.each do |name, properties|
          type = properties['type'].ljust(6)
          say("[#{type}] #{name}")
        end
      else
        say(make_message(:show_no_file, pwd))
      end
    end

    def show_result_message(result, target)
      if result
        say(make_message(:result_success, target))
      else
        say(make_message(:result_fail, target))
      end
    end

    def show_exception(e)
      say(make_message(:result_exception))
      say(e.message)
      if e.is_a?(UnauthorizedException)
        say(make_message(:unauthorized, @storage_name.downcase))
      end
    end
  end
end
