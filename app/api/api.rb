# Base Grape class
class API < Grape::API
  cascade false
  format :json
  default_format :json
  formatter :json, Grape::Formatter::Roar
  
  use GrapeLogging::Middleware::RequestLogger,
    instrumentation_key: 'grape_key',
    include: [GrapeLogging::Loggers::SelectedHeaders.new(:default)]
  
  rescue_from RuntimeError do |e|
    error! 'Internal Server Error. This has been logged.', 500
  end
  
  rescue_from ActiveRecord::RecordNotFound do
    error! "Not Found", 404
  end
  
  rescue_from Grape::Exceptions::ValidationErrors do |e|
    error! "#{e.message}", 400
  end

  helpers do
    def current_user
      error!('Please provide an Authorization header', 401) unless headers.key? 'Authorization'
      @current_user ||= User.api_authenticate(headers['Authorization'])
    rescue ActiveRecord::RecordNotFound
      error! 'Unauthorized', 401
    rescue User::Unauthorized => e
      error! "#{e.message}", 401
    end

    def authenticate!
      current_user
    end
  end

  
  desc 'API version'
  get '/version' do
    { 'version' => ENV['API_VERSION'] }
  end

  desc 'About the API'
  get '/' do
    worker_size = Sidekiq::ProcessSet.new.size rescue 0
    {
      'Cloudnet API' => ENV['API_VERSION'],
      status: {
        datacenters: Location.count,
        worker: worker_size
      }
    }
  end

  mount Routes::V1::Datacenters
  mount Routes::V1::Servers

  add_swagger_documentation(
    mount_path: '/api_docs',
    doc_version: ENV['API_VERSION'],
    info: { title: "" }
  )
  
  route :any, '*path' do
    error! "non existing path: #{params['path']}", 404
  end
end