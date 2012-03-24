require 'rake/clean'

desc "invoke tasks of setup and hardsub-all"
task :default do
  Rake::Task[:setup].invoke
  Rake::Task[:"hardsub-all"].invoke
end

directory "json"

desc "make json files from data.txt"
task :setup => %W(data.txt json) do |t|
  datafile, = *t.sources
  make_jsons_from_data datafile
end

desc "hardsub all mpeg4 files from json data"
task :"hardsub-all" do
  Dir.glob("json/*.json") do |json|
    target = json.gsub("json/", "hardsub/").gsub(".json", ".mp4")
    Rake::Task[target].invoke
  end
end

desc "softsub all mpeg4 files from json data"
task :"softsub-all" do
  Dir.glob("json/*.json") do |json|
    target = json.gsub("json/", "softsub/").gsub(".json", ".mp4")
    Rake::Task[target].invoke
  end
end

def rule2 hash
  target_regex, *sources = *hash.to_a.first
  srcs = sources.flatten.map do |src|
    proc do |t|
      t.gsub(target_regex, src)
    end
  end
  if block_given? then
    rule(target_regex => srcs) do |t|
      yield t if block_given?
    end
  else
    rule(target_regex => srcs)
  end
end

def make_json url
  doc = Nokogiri.parse(open(url).read)
  def doc.xpath _xpath
    super(_xpath).to_s
  end
  hash = {}
  hash["mp4_url"] = doc.xpath("//meta[@property='og:video']/@content").gsub("-320k.mp4", "-480p.mp4")
  order_dvd_url = doc.xpath("//a[@class='sprite dvd']/@href")
  hash["tedid"] = order_dvd_url[/showproduct.aspx\?sku=(\d+)/, 1]
  hash["tedid"] or raise "cannot find tedid on #{url}"
  task = File.basename(hash["mp4_url"], "-480p.mp4")
  jsonname = "json/#{task}.json"

  open(jsonname, "w") do |f|
    f.write hash.to_json
  end
  return true
rescue
  puts $!
  return false
end

def make_jsons_from_data datafile
  require 'json'
  require 'nokogiri'
  require 'open-uri'
  filename = File.join(File.dirname(__FILE__), datafile)

  open(filename) do |f|
    f.each_line do |line|
      url = line.chomp
      make_json url
    end
  end
end

file "data.txt" do |t|
  File.open(t.name, "w") do |f|
    1.upto(1312) do |i|
      f.puts "http://www.ted.com/talks/view/id/#{i}"
    end
  end
end

directory "none"
rule2 %r(none/(.+)\.mp4) => %W(json/\\1.json none) do |t|
  require 'json'
  target   = t.name
  jsonname = t.source
  break if File.file?(target) and
    File.mtime(jsonname) < File.mtime(target)
  json = JSON.parse(open(jsonname).read)
  url = json["mp4_url"]

  cmdline = "wget -O '#{target}' '#{url}'"
  sh cmdline
  sh "touch #{target}"
end

directory "srt"
rule2 %r(srt/(.+)-en\.srt) => %W(json/\\1.json srt) do |t|
  require 'json'
  target   = t.name
  jsonname = t.source
  download_srt target, jsonname, "en"
end

rule2 %r(srt/(.+)-ja\.srt) => %W(json/\\1.json srt) do |t|
  require 'json'
  target   = t.name
  jsonname = t.source
  download_srt target, jsonname, "ja"
end

def download_srt target, jsonname, lang
  json = JSON.parse(open(jsonname).read)
  tedid = json["tedid"]
  url = "http://www.ted.com/talks/subtitles/id/#{tedid}/lang/#{lang}/format/srt"
  cmdline = "wget -O '#{target}' '#{url}'"
  sh cmdline or
  begin
    File.unlink jsonname
  end
end

rule2 %r(srt/(.+)\.ass) =>%W(srt/\\1-ja.srt srt/\\1-en.srt) do |t|
  require 'json'
  target   = t.name
  ja, en = t.sources
  cmdline = "ruby srt2ass.rb #{ja} #{en} > #{target}"
  sh cmdline
end

directory "javideo"
rule2 %r(javideo/(.+)\.mp4) => %W(srt/\\1-ja.srt none/\\1.mp4 javideo) do |t|
  ja_srt, original = *t.sources
  bottom = "100"
  combine t.name, original, ja_srt, bottom
end

directory "hardsub"
rule2 %r(hardsub/(.+)\.mp4) => %W(srt/\\1.ass none/\\1.mp4 hardsub) do |t|
#rule2 %r(hardsub/(.+)\.mp4) => %W(srt/\\1-en.srt javideo/\\1.mp4 hardsub) do |t|
  ass, none, = *t.sources
  top = "100"
  combine t.name, none, ass, top
end

directory "softsub"
rule2 %r(softsub/(.+)\.mp4) => %W(srt/\\1-en.srt javideo/\\1.mp4 softsub)  do |t|
  en_srt, javideo, = *t.sources
  softsub t.name, javideo, en_srt
end

def combine target, original, srt, subpos
  options = {
    :source => original,
    :output => target,
    #:vf => "dsize=480:352:2,scale=-8:-8,harddup",
    :vf => "dsize=480:320:2,scale=-8:-8,expand=480:320:0:0:1,harddup",
    :of => "lavf",
    #:lavfopts => "format=mp4",
    :oac => "faac",
    :faacopts => "mpeg=4:object=2:raw:br=128",
    :ovc => "x264",
    :sws => "9",
    #subpos => "#{subpos}",
    :subcp => "utf-8",
    :"subfont-text-scale" => "3",
    #:subalign => "2",
    :sub => srt,
    :x264encopts => <<X264.chomp,
nocabac:level_idc=30:bframes=0:bitrate=512:threads=auto:global_header:threads=auto:subq=5:frameref=6:partitions=all:trellis=1:chroma_me:me=umh
X264
  }

  if ENV["DEBUG"] then
    options.merge!({
      :ss => "00:00:20",
      :endpos => "10",
    })
  end

  mencoder options
end

def mencoder options
  source = options.delete :source
  filename = options.delete :output

  argument = options.map do |key,value|
    " -#{key} #{value}"
  end.join("\\\n")

  if File.file? filename then
    STDERR.puts "#{filename} already exists!"
    return
  end

  if filename then
    filename = "-o #{filename}"
  else
    filename = ""
  end
  cmdline = "mencoder #{source} #{filename} \\\n#{argument}"
#  puts cmdline; exit
  sh cmdline
end

def softsub target, javideo, en_srt
  mp4box = "MP4Box.exe"
  cmdline = %(#{mp4box} -add "#{javideo}" -add "#{en_srt}:lang=eng:layout=0x20x0x100:size=10:font=Arial" -new "#{target}")
  sh cmdline
end
