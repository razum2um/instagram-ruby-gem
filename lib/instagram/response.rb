module Instagram
  class Response
    include Enumerable

    attr_reader :pagination
    attr_reader :meta
    attr_reader :ratelimit

    def initialize(response_hash, ratelimit_hash)
      @response_hash = response_hash

      @meta = response_hash.meta if response_hash.respond_to?(:meta)
      @pagination = response_hash.pagination if response_hash.respond_to?(:pagination)
      @next_url = @pagination && @pagination['next_url']

      @request = ratelimit_hash.delete(:request)
      @ratelimit = ::Hashie::Mash.new(ratelimit_hash)

      @data = response_hash.respond_to?(:data) ? response_hash.data : response_hash
    end

    def each(&block)
      if @next_url && @data.is_a?(Array) && !@data.empty? && (@ratelimit.remaining > 0)
        @data.each do |value|
          block.call(value)
        end
        with_timeout do
          @request.send(:request, :get, @next_url, {}, false, false, true, false, false, false).each do |value|
            @data << value
            block.call(value)
          end
        end
        @data
      else
        @data.each(&block)
      end
    end

    def method_missing(method_name, *arguments, &block)
      if @data.respond_to?(method_name)
        @data.send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      (%w(pagination meta ratelimit).include?(method_name.to_s)) || @data.send(:respond_to_missing?, method_name, include_private)
    end

    %w(is_a? kind_of?).each do |meth|
      define_method meth do |*args, &block|
        @data.send(meth, *args, &block)
      end
    end

    private

    def with_timeout
      if timeout = @request.config[:timeout]
        Timeout::timeout(timeout) do
          yield
        end
      else
        yield
      end
    rescue Timeout::Error
    end

    def self.create( response_hash, ratelimit_hash )
      new(response_hash, ratelimit_hash)
    end
  end
end
