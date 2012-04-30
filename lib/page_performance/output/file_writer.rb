module PagePerformance
  module Output
    class FileWriter
      attr_accessor :url, :request_time

      def initialize(options, results)
        @options = options
        @results = results
      end

      def create_result_file
        @result_file = File.new(@options[:output],  "w+")
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

      def write_average_results
        out = "\nAverage load time:\n-----------------------------\n"
        @results.each do | url, times |
          out += "\s#{url}: #{calculate_average_load_time(times)} ms\n"
        end
        @result_file.write(out)
      end

      def write_tag_count
        tag_scanner = Utils::TagScanner.new(@options)
        found_tags = tag_scanner.found_tags_for_urls
        out = "\nAmount of Tags found per URL:\n-----------------------------\n"
        found_tags.each do | url, tags |
          out += "\s#{url}:\n"
          tags.each do | tag, amount |
            out += "\s\s\s#{tag}: #{amount}\n"
          end
        end
        @result_file.write(out)
      end

      def write_google_speed_test_results
        google_speed_test = Utils::GooglePageSpeed.new(@options)
        speed_test_results = google_speed_test.invoke_speed_test
        out = "\nGoogleSpeedTest per URL:\n-----------------------------\n"
        speed_test_results.each do | url, result |
          out += "\s#{url}:\n"
          out += "\s\s\sscore: #{result['score']}\n"
        end
        @result_file.write(out)
      end

      def write_footer
        @result_file.write("\nTest ended at: #{Time.now}")
      end

      def calculate_average_load_time(times)
        count = times.length
        sum = 0
        times.each { |time| sum += time }
        sum / count
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
        raise PagePerformance::Error::NoUrlToTest if @options[:urls] == nil

        out = ""
        @options[:urls].each do | url | 
          out += "\s+ #{url}\n" 
        end
        out
      end

      def result_string
        "\s#{url}: #{request_time} ms\n"
      end
    end
  end
end