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
    # * Accept header:   http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
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
      def initialize(*media_types)
        media_types = media_types.flatten
        if media_types.empty?
          replace(['*/*'])
        elsif media_types.size == 1
          replace(media_types.first.split(','))
        else
          replace(media_types)
        end
      end

      def replace(media_types = [])
        super(order(media_types))
      end

      # The client's preferred media type, according to the Accept 
      # header quality params. 
      def preference_of(*types)
        types = self.class.new(*types)
        detect { |acceptable_type| types.include?(acceptable_type) }
      end

      def prioritize(*types)
        types = self.class.new(*types)
        select { |acceptable_type| types.include?(acceptable_type) }
      end

      def first_acceptable(*types)
        types = self.class.new(*types)
        types.detect { |type| include?(type) }
      end

      private

      # Order media types by quality values, and remove invalid types
      def order(media_types = [])
        media_types.map! { |t| t.is_a?(MediaType) ? t : MediaType.new(t) }
        media_types.sort!
        media_types.select { |t| t.valid? }
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
          return false unless other_media_type.is_a?(String) || other_media_type.is_a?(MediaType)
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
          quality > 0 && quality <= 1
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
