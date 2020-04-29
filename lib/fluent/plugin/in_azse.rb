#
# Copyright 2020- Ying Ge Li
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# require "fluent/plugin/input"
require "fluent/input"

module Fluent
  class AzseInput < Fluent::Input
    Fluent::Plugin.register_input("azse", self)

    unless method_defined?(:log)
      define_method(:log) { $log }
    end
  
    def initialize
      require 'net/http'
      require 'uri'
      super
    end

    config_param :endpoint, :string,   :default => 'http://169.254.169.254/metadata/scheduledevents?api-version=2019-01-01'
    config_param :interval, :time,     :default => 30
    config_param :tag_prefix, :string, :default => nil
  
    def start
      @thread = Thread.new(&method(:run))
    end
  
    def shutdown
      Thread.kill(@thread)
    end
  
    def run
      uri = URI.parse(@endpoint)
      di = -1
      loop do
        begin
          doc = call(uri)
          unless doc.nil?
            new_di = doc["DocumentIncarnation"]
            if new_di != di
              prefix = @tag_prefix ? @tag_prefix : ''
              emit(prefix, doc["Events"])
              di = new_di
            end
          end
        rescue => e
          log.error "azse: exception while processing scheduled events", :error_class=>e.class, :error=>e.message          
        end
          
        sleep @interval
      end
    end

    def call(uri)
      request = Net::HTTP::Get.new(uri)          
      request["Metadata"] = "true"
      
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        return JSON.parse(response.body)
      else
        log.warn "azse: failed to call metadata service", :http_status_code=>response.code
        return
      end
    end

    def emit(prefix, events)      
      time = Engine.now
      events.each { |event|
        tag = prefix + '.' + event["EventType"]
        router.emit(tag, time, event)
        log.debug "azse: emitted event", :tag=>tag, :time=>time, :event=>event
      }
    end
  end
end
