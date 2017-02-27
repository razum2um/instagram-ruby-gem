module Instagram
  class Response
    include Enumerable

    attr_reader :pagination
    attr_reader :meta
    attr_reader :ratelimit

    def initialize(response_hash, ratelimit_hash)
      @response_hash = response_hash
      @ratelimit_hash = ratelimit_hash
    end

    def each
    end

    def method_missing(method_name, *arguments, &block)
      if method_name.to_s =~ /user_(.*)/
        user.send($1, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.in?(%w(pagination meta ratelimit)) || @data.send(:respond_to_missing?, method_name, include_private)
    end

    def self.create( response_hash, ratelimit_hash )
      new(response_hash, ratelimit_hash)
      # data = response_hash.data.dup rescue response_hash
      # data.extend( self )
      # data.instance_exec do
      #   %w{pagination meta}.each do |k|
      #     response_hash.public_send(k).tap do |v|
      #       instance_variable_set("@#{k}", v) if v
      #     end
      #   end
      #   @ratelimit = ::Hashie::Mash.new(ratelimit_hash)
      # end
      # data
    end
  end
end
