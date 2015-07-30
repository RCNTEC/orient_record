module OrientRecord
  module Querying

    # Return array of objects
    def command(q)
      start_time = Time.now
      data = connection.command q

      # puts "OrientDB: #{sprintf('%.3f', Time.now - start_time)} #{q}"

      data['result']
    rescue Exception => e
      puts
      puts "Query: #{q}"
      puts
      puts "Error: #{e.message}"
      puts
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

    def create!(*args)
      instance = new(*args)
      fail 'Not saved' unless instance.save
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
