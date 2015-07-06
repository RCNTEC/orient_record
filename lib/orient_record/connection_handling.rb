module OrientRecord
  module ConnectionHandling
    @@connection = nil
    @@params = nil

    def credentials(params)
      if params[:database] && params[:user] && params[:password]
        @@params = params
      else
        fail 'Missing some params.'
      end
    end

    def establish_connection(params = {})
      credentials(params) if params.present?

      @@connection = Orientdb4r.client
      @@connection.connect @@params
    rescue Exception => e
      fail "Can't connect to OrientDB: #{e.message}"
    end

    def connection
      establish_connection unless @@connection
      @@connection
    end
  end
end