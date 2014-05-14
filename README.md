# CloudDoor

This gem accesses cloud storage through command line.

## Installation

Add this line to your application's Gemfile:

    gem 'cloud_door'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloud_door

## Usage

Make cloud.yml and Write your setting.

example)
onedrive:
  client_id: 0000000099999999
  client_secret: abcdefghijklmnopqrstuvwxyz
  redirect_url: https://login.live.com/oauth20_desktop.srf
  token_file: .token

## Contributing

1. Fork it ( https://github.com/KotaroHibi/cloud_door/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
