module Result
  module FrozenStruct
    def initialize(**)
      super
      freeze
    end
  end

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

    def Success(*fields, &block)
      Struct.new(*fields, keyword_init: true) do
        include FrozenStruct

        def failure?
          false
        end

        def success?
          true
        end

        class_eval(&block) if block
      end
    end

    def Model(*fields, &block)
      Struct.new(*fields, keyword_init: true) do
        include FrozenStruct
        class_eval(&block) if block
      end
    end
  end
end
