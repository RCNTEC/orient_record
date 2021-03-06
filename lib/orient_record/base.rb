module OrientRecord
  class Base
    include Virtus.model
    include ActiveModel::Validations
    extend ConnectionHandling
    extend Querying

    attribute :id, String, writer: :private

    def initialize(params = {})
      params.delete(:id)

      super params

      self.id = params['@rid'][1..-1] if params['@rid']

      @initial_attributes = attributes
    end

    def changed_attributes
      attributes.select do |key, value|
        @initial_attributes[key] != value
      end
    end

    def new_record?
      id.nil?
    end

    def save
      return false unless valid?

      if new_record?
        class_name = self.class.name
        query = "CREATE VERTEX #{class_name}"
        query += " CONTENT #{JSON.generate(attributes)}" if attributes.any?
        result = self.class.command query

        if result && result.first
          initialize(result.first)
          true
        else
          false
        end
      else
        update(attributes)
      end
    end

    def save!
      result = save
      fail 'Not saved' unless result
      result
    end

    def update(attributes)
      return false if new_record?
      return false unless valid?

      query = "UPDATE ##{id} MERGE #{JSON.generate(attributes)}"
      result = self.class.command query

      if result && result.first
        initialize(result.first)
        true
      else
        false
      end
    end

    def destroy
      return false if new_record?

      self.class.command "DELETE ##{id}"
    end

    def create_out_edge(name, target)
      fail 'Record not saved' if new_record?

      target = target.id if target.respond_to?(:id)

      field_name = "out_#{name}"
      query = "SELECT FROM ##{id}"
      result = self.class.command query

      if result.first && result.first[field_name] && result.first[field_name].include?("##{target}")
        false
      else
        query = "CREATE EDGE #{name} FROM ##{id} TO ##{target}"
        self.class.command query
      end
    end

    def create_in_edge(name, source)
      fail 'Record not saved' if new_record?

      source = source.id if source.respond_to?(:id)

      field_name = "in_#{name}"
      query = "SELECT FROM ##{id}"
      result = self.class.command query

      if result.first && result.first[field_name] && result.first[field_name].include?("##{source}")
        false
      else
        query = "CREATE EDGE #{name} FROM ##{source} TO ##{id}"
        self.class.command query
      end
    end

    def out_edges(name = nil)
      fail 'Record not saved' if new_record?

      query = "SELECT OUT('#{name}') FROM ##{id}"

      self.class.command query
    end

    def in_edges(name = nil)
      fail 'Record not saved' if new_record?

      query = "SELECT IN('#{name}') FROM ##{id}"

      self.class.command query
    end
  end
end
