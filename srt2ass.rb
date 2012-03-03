#!/usr/bin/ruby
require "pp"

$KCODE = "u"


# ass data
$ass_header = <<ASS
[Script Info]
Title: <untitled>
Original Script: <unknown>
Script Type: v4.00+
PlayResX: 0
PlayResY: 0
PlayDepth: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Top,Arial,16,&H00FFFFFF,&H000000FF,&H0016360E,&H0017460B,0,0,0,0,100,100,0,0,1,1.4,0.6,8,10,10,10,1
Style: Bottom,MS Gothic,12,&H00FFFFFF,&H000000FF,&H0016360E,&H0017460B,0,0,0,0,100,100,0,0,1,1.4,0.6,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Actor, MarginL, MarginR, MarginV, Effect, Text
ASS

$regex_srt = /^\d+\n(\d\d:\d\d:\d\d),(\d\d)\d[\ ]?-->[\ ]?(\d\d:\d\d:\d\d),(\d\d)\d(?:  SSA.*)?\n([\s\S]+)/
$ass_bottom = 'Dialogue: 0,\1.\2,\3.\4,Bottom,,0000,0000,0000,,\5'
$ass_top    = 'Dialogue: 0,\1.34,\3.\4,Top,,0000,0000,0000,,\5'

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
  end
end

def parse_srt filename, template
  split_emptyline filename do |block|
    yield block.gsub($regex_srt, template)
  end
end

def main
  puts $ass_header

  array = []
  ARGV.each do |filename|
    next unless File.file? filename
    next unless filename =~ /\.srt$/
    if filename =~ /ja.srt/
      parse_srt(filename, $ass_bottom) do |line|
        array << line
      end
    else
      parse_srt(filename, $ass_top) do |line|
        array << line
      end
    end
  end

  ary = array.sort
  first = ary.first
  if first =~ /Dialogue: 0,([.:0-9]+),([.:0-9]+),(.+?),,0000,0000,0000,,/
    ary.unshift "Dialogue: 0,00:00:00.00,#{$1.dup},#{$3.dup},,0000,0000,0000,,"
  end
  ary.each do |line|
    puts line
  end
end

main
