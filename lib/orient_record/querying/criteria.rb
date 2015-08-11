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

      def to_a
        execute

        @values
      end

      def all
        self
      end

      def size
        execute

        @values.size
      end

      def where(args)
        if args.is_a?(String)
          criteria[:conditions] = args
        elsif args.is_a?(Hash)
          criteria[:conditions].merge!(args)
        end

        self
      end

      def limit(limit)
        criteria[:limit] = limit
        self
      end

      def per(limit)
        limit(limit)
      end

      def page(page_num)
        criteria[:page] = page_num
        self
      end

      def current_page
        criteria[:page].to_i
      end

      def limit_value
        criteria[:limit].to_i
      end

      def total_count
        unless @total_count
          q = ["SELECT COUNT(*) FROM #{@klass.name}"]
          q << where_conditions
          result = @klass.command q.join(' ')
          @total_count = result.first['COUNT'].to_i
        end

        @total_count
      end

      def total_pages
        total_count / limit_value
      end

      private

      def criteria
        @criteria ||= { conditions: {} }
      end

      def execute
        return unless @values.blank?

        q = ["SELECT FROM #{@klass.name}"]

        q << where_conditions

        if criteria[:page] && criteria[:limit]
          skip_count = criteria[:page].to_i * criteria[:limit].to_i - criteria[:limit].to_i
          q << "SKIP #{skip_count}" if skip_count > 0
        end

        q << "LIMIT #{criteria[:limit]}" if criteria[:limit]

        @values = @klass.query q.join(' ')
        @count = @values.size
      end

      def where_conditions
        q = []

        if criteria[:conditions].is_a?(String) && criteria[:conditions].length > 0
          q << "WHERE #{criteria[:conditions]}"
        elsif criteria[:conditions].is_a?(Hash) && criteria[:conditions].size > 0
          q << "WHERE #{criteria[:conditions].map { |field, value| "#{field} = '#{value}'" }.join(' AND ')}"
        end

        q.join(' ')
      end
    end
  end
end
