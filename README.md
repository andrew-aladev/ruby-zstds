# Ruby bindings for zstd library

| Travis | AppVeyor | Cirrus | Circle | Codecov |
| :---:  | :---:    | :---:  | :---:  | :---:   |
| [![Travis test status](https://travis-ci.com/andrew-aladev/ruby-zstds.svg?branch=master)](https://travis-ci.com/andrew-aladev/ruby-zstds) | [![AppVeyor test status](https://ci.appveyor.com/api/projects/status/github/andrew-aladev/ruby-zstds?branch=master&svg=true)](https://ci.appveyor.com/project/andrew-aladev/ruby-zstds/branch/master) | [![Cirrus test status](https://api.cirrus-ci.com/github/andrew-aladev/ruby-zstds.svg?branch=master)](https://cirrus-ci.com/github/andrew-aladev/ruby-zstds) | [![Circle test status](https://circleci.com/gh/andrew-aladev/ruby-zstds/tree/master.svg?style=shield)](https://circleci.com/gh/andrew-aladev/ruby-zstds/tree/master) | [![Codecov](https://codecov.io/gh/andrew-aladev/ruby-zstds/branch/master/graph/badge.svg)](https://codecov.io/gh/andrew-aladev/ruby-zstds) |

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

writer = ZSTDS::Stream::Writer.new output_socket
begin
  bytes_written = writer.write_nonblock "sample string"
  # handle "bytes_written"
rescue IO::WaitWritable
  # handle wait
ensure
  writer.close
end

reader = ZSTDS::Stream::Reader.new input_socket
begin
  puts reader.read_nonblock(512)
rescue IO::WaitReadable
  # handle wait
rescue ::EOFError
  # handle eof
ensure
  reader.close
end
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

## Options

Each API supports several options:

```
:source_buffer_length
:destination_buffer_length
```

There are internal buffers for compressed and decompressed data.
For example you want to use 1 KB as source buffer length for compressor - please use 256 B as destination buffer length.
You want to use 256 B as source buffer length for decompressor - please use 1 KB as destination buffer length.

Values: 0 - infinity, default value: 0.
0 means automatic buffer length selection.

```
:compression_level
```

Values: `ZSTDS::Option::MIN_COMPRESSION_LEVEL` - `ZSTDS::Option::MAX_COMPRESSION_LEVEL`, default value: `0`.

```
:window_log
```

Values: `ZSTDS::Option::MIN_WINDOW_LOG` - `ZSTDS::Option::MAX_WINDOW_LOG`, default value: `0`.

```
:hash_log
```

Values: `ZSTDS::Option::MIN_HASH_LOG` - `ZSTDS::Option::MAX_HASH_LOG`, default value: `0`.

```
:chain_log
```

Values: `ZSTDS::Option::MIN_CHAIN_LOG` - `ZSTDS::Option::MAX_CHAIN_LOG`, default value: `0`.

```
:search_log
```

Values: `ZSTDS::Option::MIN_SEARCH_LOG` - `ZSTDS::Option::MAX_SEARCH_LOG`, default value: `0`.

```
:min_match
```

Values: `ZSTDS::Option::MIN_MIN_MATCH` - `ZSTDS::Option::MAX_MIN_MATCH`, default value: `0`.

```
:target_length
```

Values: `ZSTDS::Option::MIN_TARGET_LENGTH` - `ZSTDS::Option::MAX_TARGET_LENGTH`, default value: `0`.

```
:strategy
```

Values: `ZSTDS::Option::STRATEGIES`, default value: none.

```
:enable_long_distance_matching
```

Values: true/false, default value: none.

```
:ldm_hash_log
```

Values: `ZSTDS::Option::MIN_LDM_HASH_LOG` - `ZSTDS::Option::MAX_LDM_HASH_LOG`, default value: `0`.

```
:ldm_min_match
```

Values: `ZSTDS::Option::MIN_LDM_MIN_MATCH` - `ZSTDS::Option::MAX_LDM_MIN_MATCH`, default value: `0`.

```
:ldm_bucket_size_log
```

Values: `ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG` - `ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG`, default value: `0`.

```
:ldm_hash_rate_log
```

Values: `ZSTDS::Option::MIN_LDM_HASH_RATE_LOG` - `ZSTDS::Option::MAX_LDM_HASH_RATE_LOG`, default value: `0`.

```
:content_size_flag
```

Values: true/false, default value: true.

```
:checksum_flag
```

Values: true/false, default value: false.

```
:dict_id_flag
```

Values: true/false, default value: true.

```
:nb_workers
```

Values: `ZSTDS::Option::MIN_NB_WORKERS` - `ZSTDS::Option::MAX_NB_WORKERS`, default value: `0`.

```
:job_size
```

Values: `ZSTDS::Option::MIN_JOB_SIZE` - `ZSTDS::Option::MAX_JOB_SIZE`, default value: `0`.

```
:overlap_log
```

Values: `ZSTDS::Option::MIN_OVERLAP_LOG` - `ZSTDS::Option::MAX_OVERLAP_LOG`, default value: `0`.

```
:window_log_max
```

Values: `ZSTDS::Option::MIN_WINDOW_LOG_MAX` - `ZSTDS::Option::MAX_WINDOW_LOG_MAX`, default value: `0`.

```
:dictionary
```

Special option for dictionary, default value: none.

```
:pledged_size
```

Values: 0 - infinity, default value: 0.
It is reasonable to provide size of input (if known) for streaming api.
`String` and `File` will set `:pledged_size` automaticaly.

Please read zstd docs for more info about options.

Possible compressor options:
```
:compression_level
:window_log
:hash_log
:chain_log
:search_log
:min_match
:target_length
:strategy
:enable_long_distance_matching
:ldm_hash_log
:ldm_min_match
:ldm_bucket_size_log
:ldm_hash_rate_log
:content_size_flag
:checksum_flag
:dict_id_flag
:nb_workers
:job_size
:overlap_log
:dictionary
:pledged_size
```

Possible decompressor options:
```
:window_log_max
:dictionary
```

Example:

```ruby
require "zstds"

data = ZSTDS::String.compress "sample string", :compression_level => 5
puts ZSTDS::String.decompress(data, :window_log_max => 11)
```

HTTP encoding (`Content-Encoding: zstd`) using default options:

```ruby
require "zstds"
require "sinatra"

get "/" do
  headers["Content-Encoding"] = "zstd"
  ZSTDS::String.compress "sample string"
end
```

## String

String maintains destination buffer only, so it accepts `destination_buffer_length` option only.

```
::compress(source, options = {})
::decompress(source, options = {})
```

`source` is a source string.

## File

File maintains both source and destination buffers, it accepts both `source_buffer_length` and `destination_buffer_length` options.

```
::compress(source, destination, options = {})
::decompress(source, destination, options = {})
```

`source` and `destination` are file pathes.

## Stream::Writer

Its behaviour is similar to builtin [`Zlib::GzipWriter`](https://ruby-doc.org/stdlib-2.7.0/libdoc/zlib/rdoc/Zlib/GzipWriter.html).

Writer maintains destination buffer only, so it accepts `destination_buffer_length` option only.

```
::open(file_path, options = {}, :external_encoding => nil, :transcode_options => {}, &block)
```

Open file path and create stream writer associated with opened file.
Data will be transcoded to `:external_encoding` using `:transcode_options` before compressing.

It may be tricky to use both `:pledged_size` and `:transcode_options`. You have to provide size of transcoded input.

```
::new(destination_io, options = {}, :external_encoding => nil, :transcode_options => {})
```

Create stream writer associated with destination io.
Data will be transcoded to `:external_encoding` using `:transcode_options` before compressing.

It may be tricky to use both `:pledged_size` and `:transcode_options`. You have to provide size of transcoded input.

```
#set_encoding(external_encoding, nil, transcode_options)
```

Set another encodings, `nil` is just for compatibility with `IO`.

```
#io
#to_io
#stat
#external_encoding
#transcode_options
#pos
#tell
```

See [`IO`](https://ruby-doc.org/core-2.7.0/IO.html) docs.

```
#write(*objects)
#flush
#rewind
#close
#closed?
```

See [`Zlib::GzipWriter`](https://ruby-doc.org/stdlib-2.7.0/libdoc/zlib/rdoc/Zlib/GzipWriter.html) docs.

```
#write_nonblock(object, *options)
#flush_nonblock(*options)
#rewind_nonblock(*options)
#close_nonblock(*options)
```

Special asynchronous methods missing in `Zlib::GzipWriter`.
`rewind` wants to `close`, `close` wants to `write` something and `flush`, `flush` want to `write` something.
So it is possible to have asynchronous variants for these synchronous methods.
Behaviour is the same as `IO#write_nonblock` method.

```
#<<(object)
#print(*objects)
#printf(*args)
#putc(object, encoding: ::Encoding::BINARY)
#puts(*objects)
```

Typical helpers, see [`Zlib::GzipWriter`](https://ruby-doc.org/stdlib-2.7.0/libdoc/zlib/rdoc/Zlib/GzipWriter.html) docs.

## Stream::Reader

Its behaviour is similar to builtin [`Zlib::GzipReader`](https://ruby-doc.org/stdlib-2.7.0/libdoc/zlib/rdoc/Zlib/GzipReader.html).

Reader maintains both source and destination buffers, it accepts both `source_buffer_length` and `destination_buffer_length` options.

```
::open(file_path, options = {}, :external_encoding => nil, :internal_encoding => nil, :transcode_options => {}, &block)
```

Open file path and create stream reader associated with opened file.
Data will be force encoded to `:external_encoding` and transcoded to `:internal_encoding` using `:transcode_options` after decompressing.

```
::new(source_io, options = {}, :external_encoding => nil, :internal_encoding => nil, :transcode_options => {})
```

Create stream reader associated with source io.
Data will be force encoded to `:external_encoding` and transcoded to `:internal_encoding` using `:transcode_options` after decompressing.

```
#set_encoding(external_encoding, internal_encoding, transcode_options)
```

Set another encodings.

```
#io
#to_io
#stat
#external_encoding
#internal_encoding
#transcode_options
#pos
#tell
```

See [`IO`](https://ruby-doc.org/core-2.7.0/IO.html) docs.

```
#read(bytes_to_read = nil, out_buffer = nil)
#eof?
#rewind
#close
#closed?
```

See [`Zlib::GzipReader`](https://ruby-doc.org/stdlib-2.7.0/libdoc/zlib/rdoc/Zlib/GzipReader.html) docs.

```
#readpartial(bytes_to_read = nil, out_buffer = nil)
#read_nonblock(bytes_to_read, out_buffer = nil, *options)
```

See [`IO`](https://ruby-doc.org/core-2.7.0/IO.html) docs.

```
#getbyte
#each_byte(&block)
#readbyte
#ungetbyte(byte)

#getc
#readchar
#each_char(&block)
#ungetc(char)

#lineno
#lineno=
#gets(separator = $OUTPUT_RECORD_SEPARATOR, limit = nil)
#readline
#readlines
#each(&block)
#each_line(&block)
#ungetline(line)
```

Typical helpers, see [`Zlib::GzipReader`](https://ruby-doc.org/stdlib-2.7.0/libdoc/zlib/rdoc/Zlib/GzipReader.html) docs.

## Dictionary

You can train dictionary from samples using `train` class method.

```
::train(samples, :capacity => 0)
```

Please review zstd code before using it.
There are many validation requirements and it changes between versions.

```
#buffer
```

There is an attribute reader for buffer.
You can use it to store dictionary somewhere.

```
::new(buffer)
```

Please use regular constructor to create dictionary from buffer.

```
#id
```

Read dictionary id from buffer.

## CI

See universal test script [scripts/ci_test.sh](scripts/ci_test.sh) for CI.
Please visit [scripts/test-images](scripts/test-images).
You can run this test script using many native and cross images.

Cirrus CI uses `x86_64-pc-linux-gnu` image, Circle CI - `x86_64-gentoo-linux-musl` image.

## License

MIT license, see LICENSE and AUTHORS.
