# Much of this code was stolen from http://github.com/mynyml/rack-accept-media-types
#
# Enhancement added by me to include subtype wildcards and handling for client
# preferred media type.

module Rack
  class Request
    # The media types of the HTTP_ACCEPT header ordered according to their
    # "quality" (preference level), without any media type parameters.
    #
    # ===== Examples
    #
    #   env['HTTP_ACCEPT']  #=> 'application/xml;q=0.8,text/html,text/plain;q=0.9'
    #
    #   req = Rack::Request.new(env)
    #   req.accept_media_types          #=> ['text/html', 'text/plain', 'application/xml']
    #   req.accept_media_types.prefered #=>  'text/html'
    #
    # For more information, see:
    # * Acept header:   http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    # * Quality values: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.9
    #
    # ===== Returns
    # AcceptMediaTypes:: ordered list of accept header's media types
    #
    def acceptable_media_types
      @acceptable_media_types ||= AcceptableMediaTypes.new(@env['HTTP_ACCEPT'])
    end

    class AcceptableMediaTypes < Array
      #--
      # NOTE
      # Reason for special handling of nil accept header:
      #
      # "If no Accept header field is present, then it is assumed that the client
      # accepts all media types."
      #
      def initialize(header)
        if header.nil?
          replace([MediaType.new('*/*')])
        else
          replace(order(header.split(',')))
        end
      end

      # The client's preferred media type, according to the Accept 
      # header quality params. 
      #
      # NOTE: By default, this method follows the http spec, and goes
      # by the client's specified quality parameters. However, because 
      # some browsers (Webkit) have a broken Accept header, you may 
      # pass +true+ as the last argument, and the method will instead
      # choose the first of the types that the client indicates it will
      # accept. If you want to send HTML to browsers, make sure text/html
      # comes first in the args here.
      def preference_of(*types)
        if types.last.is_a?(TrueClass)
          workaround_busted_browsers = types.pop
        end

        types = types.size == 1 ? types.first.split(",") : types
        types.map! { |type| MediaType.new(type) }
        if workaround_busted_browsers
          # Return the first acceptable type
          types.detect { |type| include?(type) }
        else
          # Return the most acceptable type
          detect { |acceptable_type| types.include?(acceptable_type) }
        end
      end

      private

      # Order media types by quality values, and remove invalid types
      def order(types)
        types.map {|type| MediaType.new(type) }.sort.select {|type| type.valid? }
      end

      class MediaType
        include Comparable

        attr_accessor :media_type, :range, :quality

        ANY = "*"

        def initialize(media_type)
          @media_type = media_type
        end

        # media-range = ( "*/*"
        # | ( type "/" "*" )
        # | ( type "/" subtype )
        # ) *( ";" parameter )
        def range
          @range ||= media_type.split(';').first
        end

        # qvalue = ( "0" [ "." 0*3DIGIT ] )
        # | ( "1" [ "." 0*3("0") ] )
        def quality
          @quality ||= extract_quality(media_type.split(';')[1..-1])
        end

        def <=>(other)
          other.quality <=> quality
        end

        def ==(other_media_type)
          other_media_type = MediaType.new(other_media_type) unless other_media_type.is_a?(MediaType)

          if type == ANY
            true
          elsif type == other_media_type.type
            subtype == ANY || subtype == other_media_type.subtype
          else 
            false
          end
        end

        def inspect
          %Q{#<#{self.class}:0x%1x #{to_s}>} % object_id
        end

        def to_s
          @media_type
        end

        # "A weight is normalized to a real number in the range 0 through 1,
        # where 0 is the minimum and 1 the maximum value. If a parameter has a
        # quality value of 0, then content with this parameter is `not
        # acceptable' for the client."
        #
        def valid?
          self.quality.between?(0.1, 1)
        end

        def type
          @type ||= range.split('/').first
        end

        def subtype
          @subtype ||= range.split('/').last
        end

        private

        # Extract value from 'q=FLOAT' parameter if present, otherwise assume 1
        #
        # "The default value is q=1."
        #
        def extract_quality(params)
          q = params.detect {|p| p.match(/q=\d\.?\d{0,3}/) }
          q ? q.split('=').last.to_f : 1.0
        end

      end

    end
  end
end
