# Ruby bindings for zstd library

| AppVeyor | Circle | Github actions | Codecov | Gem  |
| :------: | :----: | :------------: | :-----: | :--: |
| [![AppVeyor test status](https://ci.appveyor.com/api/projects/status/github/andrew-aladev/ruby-zstds?branch=master&svg=true)](https://ci.appveyor.com/project/andrew-aladev/ruby-zstds/branch/master) | [![Circle test status](https://circleci.com/gh/andrew-aladev/ruby-zstds/tree/master.svg?style=shield)](https://circleci.com/gh/andrew-aladev/ruby-zstds/tree/master) | [![Github Actions test status](https://github.com/andrew-aladev/ruby-zstds/workflows/test/badge.svg?branch=master)](https://github.com/andrew-aladev/ruby-zstds/actions) | [![Codecov](https://codecov.io/gh/andrew-aladev/ruby-zstds/branch/master/graph/badge.svg)](https://codecov.io/gh/andrew-aladev/ruby-zstds) | [![Gem](https://img.shields.io/gem/v/ruby-zstds.svg)](https://rubygems.org/gems/ruby-zstds) |

See [zstd library](https://github.com/facebook/zstd).

## Installation

Please install zstd library first, use latest 1.4.0+ version.

Also some server installations (especially CentOS) might require [libzstd-devel](https://pkgs.org/download/libzstd-devel) package installation.

```sh
gem install ruby-zstds
```

You can build it from source.

```sh
rake gem
gem install pkg/ruby-zstds-*.gem
```

You can also use [overlay](https://github.com/andrew-aladev/overlay) for gentoo.

### Installing in macOS on Apple Silicon
On M1 Macs, Homebrew installs to /opt/homebrew, so you'll need to specify its
include and lib paths when building the native extension for zstd.

```sh
brew install zstd
gem install ruby-zstds -- --with-opt-include=/opt/homebrew/include --with-opt-lib=/opt/homebrew/lib
```

You can also configure Bundler to use those options when installing:

```sh
bundle config set build.ruby-zstds "--with-opt-include=/opt/homebrew/include --with-opt-lib=/opt/homebrew/lib"
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
File.write "dictionary.bin", dictionary.buffer, :mode => "wb"

dictionary_buffer = File.read "dictionary.bin", :mode => "rb"
dictionary        = ZSTDS::Dictionary.new dictionary_buffer

data = ZSTDS::String.compress "sample string", :dictionary => dictionary
puts ZSTDS::String.decompress(data, :dictionary => dictionary)
```

You can create and read `tar.zst` archives with [minitar](https://github.com/halostatue/minitar).

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

You can also use `Content-Encoding: zstd` with [sinatra](http://sinatrarb.com):

```ruby
require "zstds"
require "sinatra"

get "/" do
  headers["Content-Encoding"] = "zstd"
  ZSTDS::String.compress "sample string"
end
```

All functionality (including streaming) can be used inside multiple threads with [parallel](https://github.com/grosser/parallel).
This code will provide heavy load for your CPU.

```ruby
require "zstds"
require "parallel"

Parallel.each large_datas do |large_data|
  ZSTDS::String.compress large_data
end
```

## Options

| Option                          | Values         | Default    | Description |
|---------------------------------|----------------|------------|-------------|
| `source_buffer_length`          | 0 - inf        | 0 (auto)   | internal buffer length for source data |
| `destination_buffer_length`     | 0 - inf        | 0 (auto)   | internal buffer length for description data |
| `gvl`                           | true/false     | false      | enables global VM lock where possible |
| `compression_level`             | -131072 - 22   | 0 (auto)   | compression level |
| `window_log`                    | 10 - 31        | 0 (auto)   | maximum back-reference distance (power of 2) |
| `hash_log`                      | 6 - 30         | 0 (auto)   | size of the initial probe table (power of 2) |
| `chain_log`                     | 6 - 30         | 0 (auto)   | size of the multi-probe search table (power of 2) |
| `search_log`                    | 1 - 30         | 0 (auto)   | number of search attempts (power of 2) |
| `min_match`                     | 3 - 7          | 0 (auto)   | minimum size of searched matches |
| `target_length`                 | 0 - 131072     | 0 (auto)   | distance between match sampling (for `:fast` strategy), length of match considered "good enough" for (for other strategies) |
| `strategy`                      | `STRATEGIES`   | nil (auto) | choses strategy |
| `enable_long_distance_matching` | true/false     | nil (auto) | enables long distance matching |
| `ldm_hash_log`                  | 6 - 30         | 0 (auto)   | size of the table for long distance matching (power of 2) |
| `ldm_min_match`                 | 4 - 4096       | 0 (auto)   | minimum match size for long distance matcher |
| `ldm_bucket_size_log`           | 1 - 8          | 0 (auto)   | log size of each bucket in the LDM hash table for collision resolution |
| `ldm_hash_rate_log`             | 0 - 25         | 0 (auto)   | frequency of inserting/looking up entries into the LDM hash table |
| `content_size_flag`             | true/false     | true       | enables writing of content size into frame header (if known) |
| `checksum_flag`                 | true/false     | false      | enables writing of 32-bits checksum of content at end of frame |
| `dict_id_flag`                  | true/false     | true       | enables writing of dictionary id into frame header |
| `nb_workers`                    | 0 - 200        | 0 (auto)   | number of threads spawned in parallel |
| `job_size`                      | 0 - 1073741824 | 0 (auto)   | size of job (nb_workers >= 1) |
| `overlap_log`                   | 0 - 9          | 0 (auto)   | overlap size, as a fraction of window size |
| `window_log_max`                | 10 - 31        | 0 (auto)   | size limit (power of 2) |
| `dictionary`                    | `Dictionary`   | nil        | chose dictionary |
| `pledged_size`                  | 0 - inf        | 0 (auto)   | size of input (if known) |

There are internal buffers for compressed and decompressed data.
For example you want to use 1 KB as `source_buffer_length` for compressor - please use 256 B as `destination_buffer_length`.
You want to use 256 B as `source_buffer_length` for decompressor - please use 1 KB as `destination_buffer_length`.

`gvl` is disabled by default, this mode allows running multiple compressors/decompressors in different threads simultaneously.
Please consider enabling `gvl` if you don't want to launch processors in separate threads.
If `gvl` is enabled ruby won't waste time on acquiring/releasing VM lock.

`String` and `File` will set `:pledged_size` automaticaly.

You can also read zstd docs for more info about options.

| Option                | Related constants |
|-----------------------|-------------------|
| `compression_level`   | `ZSTDS::Option::MIN_COMPRESSION_LEVEL` = -131072, `ZSTDS::Option::MAX_COMPRESSION_LEVEL` = 22 |
| `window_log`          | `ZSTDS::Option::MIN_WINDOW_LOG` = 10, `ZSTDS::Option::MAX_WINDOW_LOG` = 31 |
| `hash_log`            | `ZSTDS::Option::MIN_HASH_LOG` = 6, `ZSTDS::Option::MAX_HASH_LOG` = 30 |
| `chain_log`           | `ZSTDS::Option::MIN_CHAIN_LOG` = 6, `ZSTDS::Option::MAX_CHAIN_LOG` = 30 |
| `search_log`          | `ZSTDS::Option::MIN_SEARCH_LOG` = 1, `ZSTDS::Option::MAX_SEARCH_LOG` = 30 |
| `min_match`           | `ZSTDS::Option::MIN_MIN_MATCH` = 3, `ZSTDS::Option::MAX_MIN_MATCH` = 7 |
| `target_length`       | `ZSTDS::Option::MIN_TARGET_LENGTH` = 0, `ZSTDS::Option::MAX_TARGET_LENGTH` = 131072 |
| `strategy`            | `ZSTDS::Option::STRATEGIES` = `%i[fast dfast greedy lazy lazy2 btlazy2 btopt btultra btultra2]` |
| `ldm_hash_log`        | `ZSTDS::Option::MIN_LDM_HASH_LOG` = 6, `ZSTDS::Option::MAX_LDM_HASH_LOG` = 30 |
| `ldm_min_match`       | `ZSTDS::Option::MIN_LDM_MIN_MATCH` = 4, `ZSTDS::Option::MAX_LDM_MIN_MATCH` = 4096 |
| `ldm_bucket_size_log` | `ZSTDS::Option::MIN_LDM_BUCKET_SIZE_LOG` = 1, `ZSTDS::Option::MAX_LDM_BUCKET_SIZE_LOG` = 8 |
| `ldm_hash_rate_log`   | `ZSTDS::Option::MIN_LDM_HASH_RATE_LOG` = 0, `ZSTDS::Option::MAX_LDM_HASH_RATE_LOG` = 25 |
| `nb_workers`          | `ZSTDS::Option::MIN_NB_WORKERS` = 0, `ZSTDS::Option::MAX_NB_WORKERS` = 200 |
| `job_size`            | `ZSTDS::Option::MIN_JOB_SIZE` = 0, `ZSTDS::Option::MAX_JOB_SIZE` = 1073741824 |
| `overlap_log`         | `ZSTDS::Option::MIN_OVERLAP_LOG` = 0, `ZSTDS::Option::MAX_OVERLAP_LOG` = 9 |
| `window_log_max`      | `ZSTDS::Option::MIN_WINDOW_LOG_MAX` = 10, `ZSTDS::Option::MAX_WINDOW_LOG_MAX` = 31 |

Possible compressor options:
```
:source_buffer_length
:destination_buffer_length
:gvl
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
:source_buffer_length
:destination_buffer_length
:gvl
:window_log_max
:dictionary
```

Example:

```ruby
require "zstds"

data = ZSTDS::String.compress "sample string", :compression_level => 5
puts ZSTDS::String.decompress(data, :window_log_max => 11)
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

Its behaviour is similar to builtin [`Zlib::GzipWriter`](https://ruby-doc.org/stdlib/libdoc/zlib/rdoc/Zlib/GzipWriter.html).

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

See [`IO`](https://ruby-doc.org/core/IO.html) docs.

```
#write(*objects)
#flush
#rewind
#close
#closed?
```

See [`Zlib::GzipWriter`](https://ruby-doc.org/stdlib/libdoc/zlib/rdoc/Zlib/GzipWriter.html) docs.

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

All nonblock operations for file will raise `EBADF` error on Windows.
Setting file into nonblocking mode is [not available on Windows](https://github.com/ruby/ruby/blob/master/win32/win32.c#L4388).

```
#<<(object)
#print(*objects)
#printf(*args)
#putc(object, encoding: ::Encoding::BINARY)
#puts(*objects)
```

Typical helpers, see [`Zlib::GzipWriter`](https://ruby-doc.org/stdlib/libdoc/zlib/rdoc/Zlib/GzipWriter.html) docs.

## Stream::Reader

Its behaviour is similar to builtin [`Zlib::GzipReader`](https://ruby-doc.org/stdlib/libdoc/zlib/rdoc/Zlib/GzipReader.html).

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

See [`IO`](https://ruby-doc.org/core/IO.html) docs.

```
#read(bytes_to_read = nil, out_buffer = nil)
#eof?
#rewind
#close
#closed?
```

See [`Zlib::GzipReader`](https://ruby-doc.org/stdlib/libdoc/zlib/rdoc/Zlib/GzipReader.html) docs.

```
#readpartial(bytes_to_read = nil, out_buffer = nil)
#read_nonblock(bytes_to_read, out_buffer = nil, *options)
```

See [`IO`](https://ruby-doc.org/core/IO.html) docs.

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

Typical helpers, see [`Zlib::GzipReader`](https://ruby-doc.org/stdlib/libdoc/zlib/rdoc/Zlib/GzipReader.html) docs.

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

## Thread safety

`:gvl` option is disabled by default, you can use bindings effectively in multiple threads.
Please be careful: bindings are not thread safe.
You should lock all shared data between threads.

For example: you should not use same compressor/decompressor inside multiple threads.
Please verify that you are using each processor inside single thread at the same time.

## Operating systems

GNU/Linux, FreeBSD, OSX, Windows (MinGW).

## CI

Please visit [scripts/test-images](scripts/test-images).
See universal test script [scripts/ci_test.sh](scripts/ci_test.sh) for CI.

## License

MIT license, see [LICENSE](LICENSE) and [AUTHORS](AUTHORS).
