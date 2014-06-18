require 'commander/import'
# require 'cloud_door'
# require 'cloud_door/cloud_storage'
# require 'cloud_door/dropbox'
# require 'cloud_door/onedrive'
# require 'cloud_door/exceptions'
require './lib/cloud_door'
require './lib/cloud_door/cloud_storage'
require './lib/cloud_door/dropbox'
require './lib/cloud_door/onedrive'
require './lib/cloud_door/exceptions'

module CloudDoor
  class Console
    attr_reader :drive, :storage_name

    def initialize(drive)
      @drive = CloudDoor.new(drive)
      @storage_name = @drive.show_storage_name
    end

    def config(show = false)
      if show
        show_configuration(@drive.show_configuration)
        exit
      end
      configs = ask_configuration
      result = @drive.update_configuration(configs)
      show_result_message(result, 'update configuration')
    end

    def account(show = false)
      if show
        show_account(@drive.show_account)
        exit
      end
      accounts = ask_account
      result = @drive.update_account(accounts)
      show_result_message(result, 'update account')
    end

    def auth(default = false)
      unless @drive.configuration_init?
        say "Config is not found. Please execute './#{@storage_name} config' before."
        exit
      end
      exit unless agree("Do you want to allow access to the #{@storage_name} from this system(Y/N)?")
      if default
        if @drive.isset_account?
          account = @drive.show_account
          say "found defaulut account '#{account.login_account}'. use this account."
        else
          say "Default account is not found. Please execute './#{@storage_name} account' before."
          exit
        end
      else
        say "Please input #{@storage_name} account"
        say "(hint) You can sign in automatically, if you register #{@storage_name} account on this system."
        @drive.account.login_account  = ask('account : ')
        @drive.account.login_password = ask('password: ') { |q| q.echo = '*' }
      end
      say "start a connection to the #{@storage_name}. please wait a few seconds."
      if @drive.login
        user = @drive.show_user
        # user_name = drive.get_cloud_info('user', 'display_name')
        say 'login success'
        say "login as #{user['name'] || user['display_name']}"
        say "\n"
        @drive.delete_file_list
        list = @drive.show_files
        if list.nil?
          say 'file not found'
          exit
        end
        say "you have these files on '/top'."
        list.each do |name, properties|
          type = properties['type'].ljust(6)
          say "[#{type}] #{name}"
        end
      else
        say 'login fail'
      end
    rescue => e
      show_exception(e)
    end

    def ls(file_name)
      @drive.load_token
      @drive.set_file_name(file_name)
      pwd = @drive.show_current_dir
      if file_name.nil? || file_name.empty?
        write = true
      else
        pwd << "/#{file_name}"
        write = false
      end
      list = @drive.show_files(write)
      if list.count > 0
        say "you have these files on '#{pwd}'."
        list.each do |name, properties|
          type = properties['type'].ljust(6)
          say "[#{type}] #{name}"
        end
      else
        say "you have no file on '#{pwd}'."
      end
    rescue => e
      show_exception(e)
    end

    def cd(file_name)
      if (file_name.nil? || file_name.empty?)
        say 'wrong parameter'
        exit
      end
      @drive.load_token
      @drive.set_file_name(file_name)
      list = @drive.show_files(true)
      pwd  = @drive.show_current_dir
      say "move to '#{pwd}'."
      if list.count > 0
        say "you have these files on '#{pwd}'."
        list.each do |name, properties|
          type = properties['type'].ljust(6)
          say "[#{type}] #{name}"
        end
      else
        say "you have no file on '#{pwd}'."
      end
    rescue => e
      show_exception(e)
    end

    def info(file_name)
      if (file_name.nil? || file_name.empty?)
        say 'wrong parameter'
        exit
      end
      @drive.load_token
      @drive.set_file_name(file_name)
      info = @drive.show_property
      unless (info.empty?)
        pwd = @drive.show_current_dir
        say "information of '#{pwd}/#{file_name}'."
        max = info.max { |a, b| a[0].length <=> b[0].length }
        max_len = max[0].length
        info.each do |key, value|
          say "  #{key.ljust(max_len)} : #{value}"
        end
      else
        say 'file not found'
      end
    rescue => e
      show_exception(e)
    end

    def pwd
      @drive.load_token
      say @drive.show_current_dir
    end

    def download(file_name)
      if (file_name.nil? || file_name.empty?)
        say 'wrong parameter'
        exit
      end
      @drive.load_token
      @drive.set_file_name(file_name)
      pwd = @drive.show_current_dir
      fullname = "#{pwd}/#{file_name}"
      unless @drive.file_exists?
        say "file not exists in ondrive '#{fullname}'"
        exit
      end
      if File.exists?(file_name)
        say('same name file already exists in local.')
        exit unless agree("Do you want to overwrite '#{file_name}' (Y/N)?")
      end
      result = @drive.download_file
      show_result_message(result, "'#{file_name}' download")
    rescue => e
      show_exception(e)
    end

    def upload(file_name)
      if (file_name.nil? || file_name.empty?)
        say 'wrong parameter'
        exit
      end
      @drive.load_token
      @drive.set_up_file_name(file_name)
      pwd = @drive.show_current_dir
      fullname = "#{pwd}/#{file_name}"
      unless File.exists?(file_name)
        say("'#{file_name}' not found on local.")
        exit
      end
      if File.directory?(file_name)
        say('this file is directory.')
        say("upload as '#{file_name}.zip'.")
        say("\n")
      end
      if @drive.file_exists?
        up_file = @drive.assign_upload_file_name
        fullname = "#{pwd}/#{up_file}"
        say("same name file already exists on #{@storage_name}.")
        exit unless agree("Do you want to overwrite '#{fullname}' (Y/N)?")
      end
      result = @drive.upload_file
      show_result_message(result, "'#{fullname}' upload")
    rescue => e
      show_exception(e)
    end

    def rm(file_name)
      if (file_name.nil? || file_name.empty?)
        say 'wrong parameter'
        exit
      end
      @drive.load_token
      @drive.set_file_name(file_name)
      pwd = @drive.show_current_dir
      fullname = "#{pwd}/#{file_name}"
      exit unless agree("Do you want to delete '#{fullname}' (Y/N)?")
      unless @drive.file_exists?
        say "file not exists in #{@storage_name}"
        exit
      end
      if @drive.has_file?
        say "this directory has files."
        exit unless agree("Do you want to delete these files (Y/N)?")
      end
      result = @drive.delete_file
      show_result_message(result, "'#{fullname}' delete")
    rescue => e
      show_exception(e)
    end

    def mkdir(mkdir_name)
      if (mkdir_name.nil? || mkdir_name.empty?)
        say 'wrong parameter'
        exit
      end
      @drive.load_token
      @drive.set_mkdir_name(mkdir_name)
      pwd = @drive.show_current_dir
      fullname = "#{pwd}/#{mkdir_name}"
      if @drive.file_exists?
        say("'#{fullname}' already exists on #{@storage_name}.")
        say 'mkdir fail'
        exit
      end
      result = @drive.make_directory
      show_result_message(result, "make '#{fullname}' directory")
    rescue => e
      show_exception(e)
    end

    private

    def show_configuration(config)
      say ("#{@storage_name} configuration are")
      say "  client_id    : #{config.client_id}\n"
      say "  client_secret: #{config.client_secret}\n"
      say "  redirect_url : #{config.redirect_url}\n"
    end

    def ask_configuration
      say ("Please enter the #{@storage_name} configuration.")
      configs = {}
      configs['client_id']      = ask('client_id     : ')
      configs['client_secret']  = ask('client_secret : ')
      configs['redirect_url']   = ask('redirect_url  : ')
      configs.each { |key, val| configs[key] = val.to_s }
    end

    def show_account(account)
      say ("#{@storage_name} acount are")
      say "  account : #{account.login_account}\n"
      say "  password: #{account.login_password}\n"
    end

    def ask_account
      say ("Please enter the #{@storage_name} account.")
      accounts = {}
      accounts['login_account']  = ask('login_account : ')
      accounts['login_password'] = ask('login_password: ') { |q| q.echo = '*' }
      accounts.each { |key, val| accounts[key] = val.to_s }
    end

    def show_result_message(result, target)
      if result
        say ("#{target} success.")
      else
        say ("Warning: #{target} fail.")
      end
    end

    def show_exception(e)
      say 'command failed.'
      say e.message
      if e.is_a?(UnauthorizedException)
        say "please execute '#{@storage_name} auth' command."
      end
    end
  end
end
