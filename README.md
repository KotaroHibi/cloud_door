# CloudDoor

This gem can access different cloud storage through same interface.  
This gem supports OneDrive, Dropbox and GoogleDrive.


## Installation

Add this line to your application's Gemfile:

    gem 'cloud_door'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloud_door


## usage

### prepare

This gem use cloud storage application setting.  
Please create application on below url.  

|storage|url|
|-------|---|
|OneDrive|https://account.live.com/developers/applications/index|
|Dropbox|https://www.dropbox.com/developers/apps/create|
|GoogleDrive|https://console.developers.google.com/flows/enableapi?apiid=drive|

### configuration
1. make "cloud_door_config.yml" on application root directory.
2. write application settings to "cloud_door_config.yml".
  - all
    - data_path  
      data_path is path to save data file.
      application must have write permission to data_path.
    - session_flg  
      Whether or not to switch the session for each user.
      "0" is "no" and "1" is "yes".
      must be a "1" in an environment where multiple users use application at same time.
  - onedrive
    - client_id  
      OneDrive's client id
    - client_secret  
      OneDrive's client secret
    - redirect_url  
      OneDrive's redirect url after login.
      please set to "https://login.live.com/oauth20_desktop.srf" for desktop apps.
  - dropbox
    - client_id  
      Dropbox's client id
    - client_secret  
      Dropbox's client secret
    - redirect_url  
      Dropbox's redirect url after login.
      please set to "https://localhost" for desktop apps.
  - googledrive
    - client_id  
      GoogleDrive's client id
    - client_secret  
      GoogleDrive's client secret
    - redirect_url  
      GoogleDrive's redirect url after login.
      please set to "urn:ietf:wg:oauth:2.0:oob" for desktop apps.

example  
    ```
    all:
      data_path : './data/'
      web_app_flag: 0
    onedrive:
      client_id: onedrive
      client_secret: onedrive_secret
      redirect_url: https://login.live.com/oauth20_desktop.srf
    dropbox:
      client_id: dropbox
      client_secret: dropbox_secret
      redirect_url: http://localhost
    googledrive:
      client_id: googledrive
      client_secret: googledrive_secret
      redirect_url: urn:ietf:wg:oauth:2.0:oob
    ```


### example

A.before login  
    ```ruby
    require 'cloud_door'
    require 'pp'

    # make an instance for connecting to Onedrive
    storage = CloudDoor::CloudDoor.new(CloudDoor::OneDrive)
    ## make an instance for connecting to Dropbox
    ## storage = CloudDoor::CloudDoor.new(CloudDoor::Dropbox)
    ## make an instance for connecting to GoogleDrive
    ## storage = CloudDoor::CloudDoor.new(CloudDoor::GoogleDrive)
    # login
    storage.login('account', 'password')
    # show files
    files = storage.show_files
    pp files
    # upload file
    storage.upload_file('README.md')
    # download file
    storage.download_file('README.md')
    ```

B.after login--
    ```ruby
    require 'cloud_door'
    
    storage = CloudDoor::CloudDoor.new(CloudDoor::OneDrive)
    # load_token calls the login information of previous
    storage.load_token
    ```

C.if session_flag is "1"(using session ID)--
    ```ruby
    require 'cloud_door'
    
    # login
    storage = CloudDoor::CloudDoor.new(CloudDoor::OneDrive)
    session_id = storage.login('account', 'password')
    
    # load_token
    storage = CloudDoor::CloudDoor.new(CloudDoor::OneDrive, session_id)
    storage.load_token
    ```


### methods
You can use these methods as instance method.  
these methods can operate current directory only.
- login(login_account, login_password)
  - login cloud storage.
  - return the session ID after logging in if "session_flag" is "1".  
    please hold session ID by use of uri/session
- load_token
  - load login session.
- show_user
  - return login user information as Hash.
- show_files(file_name = nil)
  - if file_name is nil, return files on current directory as Hash.
  - if file_name is not nil, return files on specified directory as Hash.
  - raise error if specified file not found.
- change_directory(file_name)
  - change current directory to specified directory.
  - return files on specified directory as Hash.
  - raise error if specified file not found.
- show_current_directory
  - return path of current directory.
- show_property(file_name)
  - return properties of specified file as Hash.
  - raise error if specified file not found.
- delete_file(file_name)
  - delete specified file from cloud storage.
  - cannot delete a directory that has files.
  - raise error if specified file not found.
- download_file(file_name)
  - download specified file from cloud storage to local.
  - cannot download directory. 
  - overwrite file if there is a file with the same name.  
    please check before if you do not want to overwrite.
  - raise error if specified file not found.
- upload_file(file_name)
  - upload specified file to cloud storage from local.
  - if specified file is a directory, Upload by zip compression automatically.
  - overwrite file if there is a file with the same name.  
    please check before if you do not want to overwrite.
  - raise error if specified file not found.
- make_directory(mkdir_name)
  - make specified directory on cloud storage.
  - raise error if there is a file with the same name.
- file_exist?(file_name)
  - make sure the specified file exists in current directory.  
    return true if the specified file exists.
- has_file?(file_name)
  - make sure the specified directory has files.  
    return true if the specified file has files.
- file?(file_name)
  - make sure the specified file is file or a directory.  
    return true if the specified file has files.
  - check if a file or directory is the corresponding element.  
    return true if the specified file is a file.
- show_storage_name
  - return storage name which "OneDrive" or "Dropbox".
- show_configuration
  - return settings on "cloud_door_config.yml" as Hash.
- update_configuration(configs)
  - update settings on "cloud_door_config.yml".
- configuration_init?
  - check if is set "cloud_door_config.yml".  
    return true if "cloud_door_config.yml" is set.
- show_account
  - return registered account as Hash.
- update_account(accounts)
  - update account.
- iseset_account?
  - check if is set account.  
    return true if account is set.


## Contributing

1. Fork it ( https://github.com/KotaroHibi/cloud_door/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

