require 'net/http'

module TeamCity

  HOSTNAME  = 'localhost'
  PORT      = '8111'
  USERNAME  = 'ethilvanci'
  require_relative 'teamcity_password'
  PATH      = '/httpAuth/action.html'

  def self.trigger(build_id, branch = 'master')

    http = Net::HTTP.new(HOSTNAME, PORT)
    path = PATH
    params = { add2Queue: build_id, branchName: branch }
    unless params.empty?
      path += '?'
      path += params.map { |key, value| "#{key}=#{value}" } * '&'
    end

    request = Net::HTTP::Get.new(path)
    request.basic_auth(USERNAME, PASSWORD)

    print "Adding build to queue for branch #{branch}..."
    response = http.request(request)
    puts response.code.to_s == '200' ? ' Ok' : ' Failed'
  end
end
