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
        attributes_part = attributes_string(attributes)
        query += " SET #{attributes_part}" unless attributes_part.blank?
        rows = self.class.command query
        rows ? initialize(rows.first) : false
      else
        update(attributes)
      end
    end

    def update(attributes = {})
      return false if new_record?

      attributes_part = attributes_string(attributes)
      query = "UPDATE ##{id} SET #{attributes_part}"

      self.class.command query
    end

    def destroy
      return false if new_record?

      self.class.command "DELETE ##{id}"
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

    def attributes_string(attributes)
      attributes.map { |k, v| "#{k} = '#{v.gsub(/['"\\\x0]/,'\\\\\0')}'" }.join(', ')
    end
  end
end
