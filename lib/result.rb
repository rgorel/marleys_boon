module Result
  Failure = Struct.new(:error) do
    def failure?
      true
    end

    def success?
      false
    end
  end

  class << self
    def Failure(error)
      Failure.new(error).freeze
    end

    def Success(*fields)
      Struct.new(*fields, keyword_init: true) do
        def initialize(**)
          super
          freeze
        end

        def failure?
          false
        end

        def success?
          true
        end
      end
    end

    def Model(*fields)
      Struct.new(*fields, keyword_init: true) do
        def initialize(**)
          super
          freeze
        end
      end
    end
  end
end
