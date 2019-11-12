# Ruby bindings for zstd library

| Travis | AppVeyor | Cirrus | Circle |
| :---:  | :---:    | :---:  | :---:  |
| [![Travis test status](https://travis-ci.com/andrew-aladev/ruby-zstds.svg?branch=master)](https://travis-ci.com/andrew-aladev/ruby-zstds) | [![AppVeyor test status](https://ci.appveyor.com/api/projects/status/github/andrew-aladev/ruby-zstds?branch=master&svg=true)](https://ci.appveyor.com/project/andrew-aladev/ruby-zstds/branch/master) | [![Cirrus test status](https://api.cirrus-ci.com/github/andrew-aladev/ruby-zstds.svg?branch=master)](https://cirrus-ci.com/github/andrew-aladev/ruby-zstds) | [![Circle test status](https://circleci.com/gh/andrew-aladev/ruby-zstds/tree/master.svg?style=shield)](https://circleci.com/gh/andrew-aladev/ruby-zstds/tree/master) |

See [zstd library](https://github.com/facebook/zstd).

## Installation

Please install zstd library first, use latest 1.4.3+ version.

```sh
gem install ruby-zstds
```

You can build it from source.

```sh
rake gem
gem install pkg/ruby-zstds-*.gem
```

## Usage

There are simple APIs: `String` and `File`. Also you can use generic streaming API: `Stream::Writer` and `Stream::Reader`.

```ruby
require "zstds"

data = ZSTDS::String.compress "sample string"
puts ZSTDS::String.decompress(data)

ZSTDS::File.compress "file.txt", "file.txt.zst"
ZSTDS::File.decompress "file.txt.zst", "file.txt"

ZSTDS::Stream::Writer.open("file.txt.zst") { |writer| writer << "sample string" }
puts ZSTDS::Stream::Reader.open("file.txt.zst") { |reader| reader.read }
```

You can create dictionary using `ZSTDS::Dictionary`.

```ruby
require "securerandom"
require "zstds"

samples = (Array.new(8) { ::SecureRandom.random_bytes(1 << 8) } + ["sample string"]).shuffle

dictionary = ZSTDS::Dictionary.train samples
File.write "dictionary.bin", dictionary.buffer

dictionary_buffer = File.read "dictionary.bin"
dictionary        = ZSTDS::Dictionary.new dictionary_buffer

data = ZSTDS::String.compress "sample string", :dictionary => dictionary
puts ZSTDS::String.decompress(data, :dictionary => dictionary)
```

You can create and read `tar.zst` archives with `minitar` for example.

```ruby
require "zstds"
require "minitar"

ZSTDS::Stream::Writer.open "file.tar.zst" do |writer|
  Minitar::Writer.open writer do |tar|
    tar.add_file_simple "file", :data => "sample string"
  end
end

ZSTDS::Stream::Reader.open "file.tar.zst" do |reader|
  Minitar::Reader.open reader do |tar|
    tar.each_entry do |entry|
      puts entry.name
      puts entry.read
    end
  end
end
```

WIP

## License

MIT license, see LICENSE and AUTHORS.
