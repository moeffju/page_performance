require 'json'

module PagePerformance
  module Utils
    # integration of the Google PageSpeed api
    class GooglePageSpeed < HttpHelper
      attr_accessor :results

      def initialize(options)
        @options = options
        @results = {}
        @google_page_speed_url = 'https://www.googleapis.com/pagespeedonline/v1/runPagespeed'
      end

      def invoke_speed_test
        results = {}
        urls.each do | url |
          speed_test_result = speed_test(formated_url(url))
          results[url] = JSON.parse(speed_test_result.body)
        end
        results
      end

      def speed_test(url)
        url_parts = {:url => url, :key => @options[:google_api_key], :prettyprint => false }
        url_string = url_parts.map { |key, val| "#{key}=#{val}"}.join('&')
        url = [@google_page_speed_url, url_string].join('?')
        fetch_url(url)
      end

      def urls
        urls = @options[:urls]
        raise PagePerformance::Error::NoUrlToTest if urls == nil
        urls.map { | url | url }
      end
    end
  end
end