require 'httparty'
require 'mcrypt'

class SnapApi
  ENCRYPTION_KEY = "M02cnQ51Ji97vwT4"
  TYPE_TO_CODE = {
    jpeg: 0,
    mp4: 1
  }

  def initialize(username, password)
    @username = username
    @password = password
    @client = SnapClient.new
  end

  def login
    path = "/ph/login"
    params = {
      'username' => @username,
      'password' => @password,
    }

    response = @client.post(path, params).parsed_response
    @auth_token = response["auth_token"]
  end

  # just because SnapChat does the weird conflation
  # of index fetching and login
  # doesn't mean I have to
  def snaps
    path = "/ph/login"
    params = {
      'username' => @username,
      'password' => @password,
    }

    response = @client.post(path, params).parsed_response
    @auth_token = response["auth_token"]
    response["snaps"]
  end

  def blob(id)
    path = "/ph/blob"
    params = {
      id: id,
      username: @username
    }

    result = @client.post(path, params, {}, @auth_token).parsed_response
    decrypt(result)
  end

  def upload(data, duration, recipients)
    headers = {
      "Content-type" => "multipart/form-data"
    }

    path = "/ph/upload"
    params = {
      username: @username,
      type: TYPE_TO_CODE[format(data)],
      data: encrypt(data),
      duration: duration
      media_id: @username.upcase + Time.now.to_i.to_s
    }
    @client.post(path, params, headers, @auth_token)

    path = "/ph/send"
    params = {
      username: @username, 
      time: duration,
      media_id: media_id
    }
    recipients.each do |recipient| 
      params[:recipient] = recipient
      @client.post(path, params, headers, @auth_token)
    end
  end

  private

  def decrypt(data)
    return data unless encrypted?(data)
      
    crypter = Mcrypt.new(:rijndael_128, :ecb, ENCRYPTION_KEY)
    crypter.decrypt(data)
  end

  def encrypt(data)
    return data if encrypted?(data)

    crypter = Mcrypt.new(:rijndael_128, :ecb, ENCRYPTION_KEY)
    crypter.encrypt(data)
  end

  # to call this 'heuristic' would be a bit of an understatement
  def format(data)
    first = data[0].ord
    second = data[1].ord

    if first == 0 
      return :mp4
    elsif (first == 0xFF && second == 0xD8)
      return :jpeg
    else
      return :encrypted
    end
  end

  def encrypted?(data)
    format(data) == :encrypted
  end

  class SnapClient
    CLIENT_PARAMS = {
      pattern: "0001110111101110001111010101111011010001001110011000110001000110".split(""),
      secret: "iEk21fuwZApXlz93750dmW22pw389dPwOk",
      static_token: "m198sOkJEn37DjqZ32lpRu76xmw288xSQ9",
      url: "https://feelinsonice.appspot.com",
      user_agent:  "Snaphax 4.0.1 (iPad; iPhone OS 6.0; en_US)"
    }

    def initialize(options = {})
      @options = options.merge(CLIENT_PARAMS)
    end

    def post(path, params = {}, headers = {}, auth_token = nil)
      auth_token ||= @options[:static_token]
      full_url = @options[:url] + path

      tstamp = timestamp
      params[:req_token] = hash(auth_token, tstamp)
      params[:timestamp] = tstamp
      headers["User-Agent"] = @options[:user_agent]

      HTTParty.post(full_url, {body: params, headers: headers})
    end

    def hash(auth_token, timestamp)
      s0 = @options[:secret] + auth_token
      s1 = timestamp.to_s + @options[:secret]

      hash0 = sha256(s0)
      hash1 = sha256(s1)

      # interleave the two hashes based on the pattern
      out = ""
      @options[:pattern].each_with_index do |digit, index|
        out = out + (digit == "0" ? hash0[index] : hash1[index])
      end

      out
    end

    def sha256(input)
      Digest::SHA256.new.hexdigest(input)
    end

    def timestamp
      Time.now.to_i
    end
  end
end
