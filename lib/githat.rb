require 'pygments.rb'
require 'pagination'

module Diff
  def main(argv=nil)
    output = ''
    infos = files_infos(argv)
    infos.map do |file|
      output << parse_diff(file)
    end
    output
  end

  def files_infos(argv)
    files = []
    names = argv == [] ? files_names : argv
    names.map do |name|
      files << { name: name, diff: file_diff(name) }
    end
    files
  end

  def parse_diff(file_info)
    extension = file_extension(file_info[:name])
    splited = split_diff(file_info[:diff])
    heads, codes = splited[:heads], splited[:codes]
    complete_file_diff = ''

    (0...heads.size).map do |i|
      parsed_head = parse_with_diff(heads[i])
      parsed_code = parse_with_lang(codes[i], extension)
      parsed_code = parse_with_diff(parsed_code)
      complete_file_diff << (parsed_head << parsed_code << "\n")
    end

    complete_file_diff
  end

  def file_extension(file_name)
    extension = file_name.gsub /(.+\.)/, ''
    if extension.empty? || file_name == extension
      extension = files_with_no_extension[file_name]
      extension ||= 'text'
    end
    extension.to_sym
  end

  def split_diff(diff)
    { heads: split_heads(diff),
      codes: split_codes(diff) }
  end

  def split_codes(diff)
    codes = diff.split(/^@@ .* @@/)
    codes[1..codes.size]
  end

  def split_heads(diff)
    heads = diff.scan(/^diff --git(?:.*\n){4}@@ .* @@/)
    heads << diff.scan(/^@@ .* @@/).tap(&:shift)
    heads.flatten
  end

  def file_diff(file)
    `git diff #{file}`
  end

  def files_names
    git_status.scan(/modified: .*/).map { |n| n.gsub(/modified: */, '') }
  end

  def git_status
    `git status`
  end

  def parse_with_lang(code, lang)
    process(code, lang)
  end

  def parse_with_diff(code)
    process(code, :diff)
  end

  def files_with_no_extension
    {
      'Gemfile' => :rb,
      'Gemfile.lock' => :rb,
      'Rakefile' => :rb,
      'Makefile' => :makefile
    }
    # TODO: support it: .*rake == rb
  end

  def process(code, lexer)
    Pygments.highlight code, formatter: 'terminal', lexer: lexer
  end
end

