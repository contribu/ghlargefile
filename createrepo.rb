
require 'fileutils'

src = ARGV[0]
dir = ARGV[1]
repo = ARGV[2]

max_size = 49 * 1024 * 1024

FileUtils.mkdir_p(dir)

# srcを分割

# https://stackoverflow.com/questions/1682120/read-a-file-in-chunks-in-ruby

download_url = lambda { |rel_path|
  "https://raw.githubusercontent.com/#{repo}/master/#{rel_path}"
}

class File
  def each_chunk(chunk_size)
    yield read(chunk_size) until eof?
  end
end

file_count = 0

File.open(src, "rb") do |f|
  f.each_chunk(max_size) { |chunk|
    File.binwrite("#{dir}/#{file_count}", chunk)
    file_count += 1
  }
end

download_command = (0..file_count - 1).map do |idx|
  "curl -L #{download_url.call(idx)} > #{idx}"
end.join("\n")

files_str = (0..file_count - 1).to_a.join(' ')

download_script = <<-EOS
#!/bin/bash

# usage
# curl #{download_url.call('download.sh')} | OUTPUT=/path/to/output sh

set -ex

dir=$(mktemp -d)
cd $dir
#{download_command}

cat #{files_str} > $OUTPUT
rm -rf $dir
EOS

File.write("#{dir}/download.sh", download_script)
