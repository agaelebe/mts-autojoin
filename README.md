# Mts-autojoin

This gem is a command line tool used to automatically join mts files from a given folder based on their file size using [ffmpeg concat demuxer](https://trac.ffmpeg.org/wiki/Concatenate)

Usually AVCHD format (used in most camcorders) breaks long video files in 2 (or 4) gigabyte chunks with file names '00001.mts', '00002.mts', '00003.mts' and so on.

This is useful if your video editor sofware doesn't support AVCHD or need to reencode the files to edit them, which is much slower than just muxing them using ffmpeg.

## Installation

Please make sure you have installed ffmpeg command line tool and have it added to your path.

Add this line to your application's Gemfile:

```ruby
gem 'mts-autojoin'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mts-autojoin

## Usage

Execute:

  $ mts-autojoin <FOLDER_WITH_MTS_FILES>


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mts-autojoin. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mts::Autojoin project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mts-autojoin/blob/master/CODE_OF_CONDUCT.md).
