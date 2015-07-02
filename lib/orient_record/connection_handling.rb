module OrientRecord
  module ConnectionHandling
    @@connection = nil

    def establish_connection(params = {})
      @params = params unless params.blank?
      @@connection = Orientdb4r.client
      @@connection.connect @params
    rescue
      fail "Can't connecto to OrientDB"
    end

    def connection
      establish_connection unless @@connection
      @@connection
    end
  end
end