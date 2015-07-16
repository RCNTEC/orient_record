module OrientRecord
  module Querying

    # Should be used for schema definition
    def attributes(*args)
      args.each do |attr_name|
        define_method(attr_name.to_s) do
          instance_variable_get("@#{attr_name}")
        end

        define_method("#{attr_name.to_s}=") do |value|
          old_value = instance_variable_get("@#{attr_name}")
          instance_variable_set("@#{attr_name}", value)
          @changed_attributes << attr_name if old_value != value && !@changed_attributes.include?(attr_name)
        end
      end
    end

    # Return array of objects
    def command(q)
      start_time = Time.now
      data = connection.command q

      puts
      puts "OrientDB: #{(Time.now - start_time).round(3)} #{q}"
      puts "          #{caller[0]}"
      puts "          #{caller[1]}"
      puts "          #{caller[2]}"
      puts

      data['result']
    end

    # Return collection of objects
    def query(q)
      rows = command q
      rows.collect { |row| new(row) }
    end

    def find(id)
      id = '#' + id if id[0] != '#'
      rows = command "SELECT FROM #{self.name} WHERE @rid = #{id}"
      rows.first ? new(rows.first) : nil
    end

    def find_or_initialize_by(*args)
      instance = where(*args).first
      instance || new(*args)
    end

    def find_or_create_by(*args)
      instance = where(*args).first
      instance || create(*args)
    end

    def create(*args)
      instance = new(*args)
      instance.save
      instance
    end

    def all
      Criteria.new(self).all
    end

    def where(args)
      Criteria.new(self).where(args)
    end

    def limit(args)
      Criteria.new(self).limit(args)
    end
  end
end
