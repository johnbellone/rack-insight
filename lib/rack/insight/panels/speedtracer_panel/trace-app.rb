module Rack::Insight
  module SpeedTracer
    class TraceApp
      include Database::RequestDataClient

      CONTENT_TYPE = 'application/json;charset=UTF-8'.freeze

      FourOhFour = [404, {"Content-Type" => "text/html"}, "App tracker doesn't know that path or id"].freeze

      class << self
        attr_accessor :has_table
      end
      self.has_table = true

      def initialize
        table_setup("speedtracer", "uuid")
        key_sql_template = "'%s'"
      end

      def call(env)
        resp = Rack::Response.new('', 200)
        resp['Content-Type'] = CONTENT_TYPE

        case env['REQUEST_METHOD']
        when 'HEAD' then
          # SpeedTracer dispatches HEAD requests to verify the
          # tracer endpoint when it detects the X-TraceUrl
          # header for the first time. After the initial load
          # the verification is cached by the extension.
          #
          # By default, we'll return 200.

        when 'GET' then
          # GET requests for specific trace are generated by
          # the extension when the user expands the network
          # resource tab. Hence, server-side tracer data is
          # request on-demand, and we need to store it for
          # some time.
          #

          qs = Rack::Utils.parse_query(env['QUERY_STRING'])
          if qs['id'] && (trace = @table.retrieve("uuid = '#{qs['id']}'"))
            resp.write trace.to_json
          else
            # Invalid request or missing request trace id
            return FourOhFour
          end
        else
          # SpeedTracer should only issue GET & HEAD requests
          resp.status = 400
        end

        return resp.finish
      end
    end
  end
end
