module HttpAuthConcern  
    extend ActiveSupport::Concern
    included do
        before_action :http_authenticate
    end
    def http_authenticate
        return true unless Rails.env == 'production'
        authenticate_or_request_with_http_basic do |username, password|
            ENV['admin'].blank? || (username == ENV['admin'] && password == ENV['admin_password'])
        end
    end
end