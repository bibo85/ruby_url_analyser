#!/usr/bin/env ruby

require 'optparse'
require 'uri'
require 'net/http'

class UrlAnalyser

  def initialize(options)
    @attempts = options[:attempts] || 10
    @file = options[:file]
    @urls_rating = { A: [], B: [], C: [], D: [], E: [], F: [] }
    @is_correct_url = true
  end

  def urls_analysis
    File.open(@file, 'r') do |file|
      file.each do |url|
        avg_load_time, size = get_size_and_time_response(url.chomp)
        if size
          if avg_load_time < 1
            rating = :A
          elsif 1 <= avg_load_time < 5
            rating = :B
          elsif 5 <= avg_load_time < 10
            rating = :C
          elsif 10 <= avg_load_time < 20
            rating = :D
          else
            rating = :E
          end
          @urls_rating[rating] << { url: url.chomp, size: size, avg_load_time: avg_load_time }
        end
      end
    end
  end

  def print_rating
    puts
    @urls_rating.each do |key, val|
      unless val.empty?
        puts "#{key}-rating:"
        val = val.sort_by { |elem| elem[:size] }
        val.each do |url_data|
          puts "#{url_data[:url]} - #{url_data[:avg_load_time]}sec - #{url_data[:size]}kb"
        end
        puts
      end
    end
  end

  private

  def get_size_and_time_response(url)
    begin
      page_size = 0
      load_time = 0

      10.times do
        start = Time.now
        response = Net::HTTP.get_response(URI(url))
        case response
        when Net::HTTPRedirection
          url = get_final_url(url)
          if url
            response = Net::HTTP.get_response(URI(url))
            page_size = response.body.size / 1024
            load_time += Time.now - start
          else
            puts "foo - invalid url" if @is_correct_url
            @is_correct_url = false
            print "#{url} - Не удалось получить конечный url, возможно слишком много редиректов\n"
          end

        when Net::HTTPClientError
          puts "foo - invalid url" if @is_correct_url
          @is_correct_url = false
          print "#{url} - #{response.code}\n"
          return
        when Net::HTTPServerError
          @urls_rating[:F] << { url: url, code: response.code }
          return
        else
          page_size = response.body.size / 1024
          load_time += Time.now - start
        end
        return (load_time / @attempts).round(3), page_size
      end

    rescue SocketError => e
      puts "foo - invalid url" if @is_correct_url
      @is_correct_url = false
      print "#{url} - Не удалось открыть TCP-соединение\n"
    rescue ArgumentError => e
      puts "foo - invalid url" if @is_correct_url
      @is_correct_url = false
      print "#{url} - некорректный url\n"
    rescue Errno::ECONNREFUSED
      puts "foo - invalid url" if @is_correct_url
      @is_correct_url = false
      print "#{url} - Не удается получить доступ к сайту. Проверьте корректность адреса\n"
    end
  end

  def get_final_url(url)
    10.times do
      headers = {
        "User-Agent" =>
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
      }
      res = Net::HTTP.get_response(URI(url), headers = headers)
      case res
      when Net::HTTPSuccess
        return url
      when Net::HTTPRedirection
        # puts "Редирект на #{res['Location']}"
        url = res['Location']
        next
      else
        return
      end
    end
  end
end

options = {}

begin
  OptionParser.new do |parser|
    parser.banner = "Usage: url_analyser.rb [options]"
    parser.on("-a",
              "--attempts [INTEGER]",
              "Необязательный аргумент. Количество попыток для опроса url (по умолчанию 10)",
              Integer) do |attempts|
      options[:attempts] = attempts || 10
    end
    parser.on("-f",
              "--file STRING",
              "Обязательный аргумент. Путь к файлу. Абсолютный или относительный",
              String) do |file|
      options[:file] = file
    end
  end.parse!

rescue OptionParser::InvalidArgument => e
  puts "#{e.message}. Неверные аргументы. Введите -h,--help для получения справки."
  exit
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts "Пропущены обязательные аргументы. Введите -h,--help для получения справки."
  exit
end

if !options[:file].strip.empty?
  if File.file?(options[:file])
    analyser = UrlAnalyser.new(options)
    analyser.urls_analysis
    analyser.print_rating
  else
    puts "Ошибка! Проверьте корректность указания пути к файлу"
  end
else
  puts "Не передан файл"
end
