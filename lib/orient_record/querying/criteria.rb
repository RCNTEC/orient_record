module OrientRecord
  module Querying
    class Criteria
      include Enumerable
      extend Forwardable

      def initialize(klass)
        @klass = klass
        @values = []
      end

      def each
        execute

        @values.each do |value|
          yield value
        end
      end

      def [](*args)
        execute

        @values[*args]
      end

      def all
        self
      end

      def size
        execute

        @values.size
      end

      def where(args)
        if args.kind_of?(String)
          criteria[:conditions] = args
        elsif args.kind_of?(Hash)
          criteria[:conditions].merge!(args)
        end

        self
      end

      def limit(limit)
        criteria[:limit] = limit
        self
      end

      private

      def criteria
        @criteria ||= { conditions: {} }
      end

      def execute
        return unless @values.blank?

        q = ["SELECT FROM #{@klass.name}"]

        if criteria[:conditions].kind_of?(String) && criteria[:conditions].length > 0
          q << "WHERE #{criteria[:conditions]}"
        elsif criteria[:conditions].kind_of?(Hash) && criteria[:conditions].size > 0
          q << "WHERE #{criteria[:conditions].map { |field, value| "#{field} = '#{value}'" }.join(' AND ')}"
        end

        if criteria[:limit]
          q << "LIMIT #{criteria[:limit]}"
        end

        @values = @klass.query q.join(' ')
      end
    end
  end
end
