#!/usr/bin/ruby
require "pp"

$KCODE = "u"

def split_emptyline filename
  open(filename) do |f|
    block = ""
    f.each_line do |line|
      if line =~ /^$/ then
        yield block
        block = ""
      else
        block << line
      end
    end
    yield block
  end
end

def parse_srt filename
  split_emptyline filename do |block|
    next if block == ""
    regex = /^\d+\n(\d\d:\d\d:\d\d,\d\d\d[\ ]?-->[\ ]?\d\d:\d\d:\d\d,\d\d\d)(?:  SSA.*)?\n([\s\S]+)/
    block =~ regex
    yield $1, $2
  end
end

def main
  array = []
  ARGV.each do |filename|
    next unless File.file? filename
    next unless filename =~ /\.srt$/
    parse_srt(filename) do |duration, sentence|
      array << [duration, sentence]
    end
  end

  i = 1
  array.group_by do |duration, sentence|
    duration
  end.sort_by do |duration, sentences|
    duration
  end.each do |duration, _|
    first  = _[0][1]
    second = _[1][1]
    puts i
    puts duration
    puts first
    puts second
    puts
    i += 1
  end
end

main
