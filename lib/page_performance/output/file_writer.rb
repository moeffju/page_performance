module PagePerformance
  module Output
    # generates and writes output to a file
    class FileWriter
      attr_accessor :url, :request_answer

      def initialize(options, results)
        @options = options
        @results = results
        set_file_name
      end

      def set_file_name
        @file_name = @options[:output]
        if File.exist?(@file_name)
          @file_name = rename_file_name
        end
      end

      def create_result_file
        @result_file = File.new(@file_name,  "w+")
        @result_file.write(file_header)
      end

      def write_to_file
        @result_file.write(result_string)
      end

      def write_summary
        write_average_results
        write_tag_count if @options[:scan_tags]
        write_google_speed_test_results if @options[:google_api_key]
        write_footer
      end

      private

      def rename_file_name
        file_renamer = Utils::FileRenamer.new(@file_name)
        file_renamer.rename
      end

      def write_average_results
        out = "\nAverage load time:\n-----------------------------\n"
        @results.each do | url, times |
          @times = times
          out += "\s#{url}: #{calculate_average_load_time} ms\n"
        end
        @result_file.write(out)
      end

      def write_tag_count
        tag_scanner = Utils::TagScanner.new(@options)
        @found_tags = tag_scanner.found_tags_for_urls
        out = "\nAmount of Tags found per URL:\n-----------------------------\n"
        out += found_tags
        @result_file.write(out)
      end

      def found_tags
        out = ''
        @found_tags.each do | url, tags |
          @tags = tags
          out += "\s#{url}:\n#{tag_count_tags}"
        end
        out
      end

      def tag_count_tags
        out = ''
        @tags.each do | tag, amount |
          out += "\s\s\s#{tag}: #{amount}\n"
        end
        out
      end

      def write_google_speed_test_results
        google_speed_test = Utils::GooglePageSpeed.new(@options)
        @speed_test_results = google_speed_test.invoke_speed_test
        @result_file.write(google_speed_test_results_body)
      end

      def google_speed_test_results_body
        out = "\nGoogleSpeedTest per URL:\n-----------------------------\n"
        @speed_test_results.each do | url, result |
          out += "\s#{url}:\n"
          out += "\s\s\sID: #{result['id']}\n"
          out += "\s\s\sTitle: #{result['title']}\n"
          out += "\s\s\sHTTP-Response Code: #{result['responseCode']}\n"
          out += "\s\s\sScore: #{result['ruleGroups']['SPEED']['score']}\n"
          out += "\n\s\s\sPage Statistics:\n"
          out += "\tNumber of Resources:\t\t#{result['pageStats']['numberResources']}\n"
          out += "\tNumber of different hosts:\t#{result['pageStats']['numberHosts']}\n"
          out += "\tNumber of static ressources:\t#{result['pageStats']['numberStaticResources']}\n"
          out += "\tTotal Request-Bytes:\t\t#{number_format(result['pageStats']['totalRequestBytes'])} KB\n"
          out += "\tHTML-Response-Bytes:\t\t#{number_format(result['pageStats']['htmlResponseBytes'])} KB\n"
          out += "\tNumber of CSS ressources:\t#{result['pageStats']['numberCssResources']}\n"
          out += "\tCSS-Response-Bytes:\t\t#{number_format(result['pageStats']['cssResponseBytes'])} KB\n"
          out += "\tNumber of JS ressources:\t#{result['pageStats']['numberJsResources']}\n"
          out += "\tJavaScript-Response-Bytes:\t#{number_format(result['pageStats']['javascriptResponseBytes'])} KB\n"
          out += "\tImage-Response-Bytes:\t\t#{number_format(result['pageStats']['imageResponseBytes'])} KB\n"
          out += "\tOther-Response-Bytes:\t\t#{number_format(result['pageStats']['otherResponseBytes'])} KB\n"
        end
        out
      end

      def number_format(number, dividor = 1024)
        '%.2f' % (number.to_i / dividor)
      end

      def write_footer
        @result_file.write("\nTest ended at: #{Time.now}")
      end

      def calculate_average_load_time
        sum = 0
        @times.each { |time| sum += time.to_i }
        sum / @times.length
      end

      def file_header
        text = <<END
PagePerformance test results
============================

Test started at: #{Time.now}

Results for performance tests for the following URLs:

#{url_list}

Results:
--------
END
      end

      def url_list
        urls = @options[:urls]
        raise PagePerformance::Error::NoUrlToTest if urls == nil

        out = ""
        urls.each do | url |
          out += "\s+ #{url}\n"
        end
        out
      end

      def result_string
        result = request_answer.to_i.is_a?(Fixnum) ? "#{request_answer} ms" : request_answer
        "\s#{url}: #{result}\n"
      end
    end
  end
end