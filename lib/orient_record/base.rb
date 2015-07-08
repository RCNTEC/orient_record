module OrientRecord
  class Base
    extend ConnectionHandling
    extend Querying

    attr_reader :id

    def initialize(attributes = {})
      @attributes = attributes
      @changed_attributes = []

      prepare
    end

    def new_record?
      @id.nil?
    end

    def save
      return true if @changed_attributes.size == 0

      attributes = {}
      @changed_attributes.each { |attr| attributes[attr] = instance_variable_get("@#{attr.to_s}") }

      if new_record?
        class_name = self.class.name
        query = "CREATE VERTEX #{class_name}"
        query += " CONTENT #{JSON.generate(attributes)}" if attributes.any?

        self.class.command query
      else
        update(attributes)
      end
    end

    def update(attributes)
      return false if new_record?

      query = "UPDATE ##{id} MERGE #{JSON.generate(attributes)}"

      self.class.command query
    end

    def destroy
      return false if new_record?

      self.class.command "DELETE ##{id}"
    end

    def create_out_edge(name, target)
      fail 'Record not saved' if new_record?

      target = target.id if target.respond_to?(:id)

      query = "CREATE EDGE #{name} FROM ##{id} TO ##{target}"

      self.class.command query
    end

    def create_in_edge(name, source)
      fail 'Record not saved' if new_record?

      source = source.id if source.respond_to?(:id)

      query = "CREATE EDGE #{name} FROM ##{source} TO ##{id}"

      self.class.command query
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

    private

    def prepare
      @attributes.each do |k, v|
        if k == '@rid'
          instance_variable_set('@id', v[1..-1])
          next
        elsif k[0] == '@'
          next
        else
          # send("#{k}=", v)
          # method("#{k}=").call(v)
          instance_variable_set("@#{k}", v)
          @changed_attributes << k
        end
      end

      @changed_attributes = [] if @attributes.keys.include?('@rid')
    end
  end
end
