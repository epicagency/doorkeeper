module Doorkeeper::OAuth
  class PasswordAccessTokenRequest
    include Doorkeeper::Validations
    include Doorkeeper::OAuth::Helpers

    ATTRIBUTES = [
      :client_id,
      :client_secret,
      :grant_type,
      :username,
      :password,
			:scope
    ]

    validate :attributes,   :error => :invalid_request
    validate :grant_type,   :error => :unsupported_grant_type
    validate :client,       :error => :invalid_client
    validate :scope,        :error => :invalid_scope

    attr_accessor *ATTRIBUTES
    attr_accessor :resource_owner

    def initialize(owner, attributes = {})
      ATTRIBUTES.each { |attr| instance_variable_set("@#{attr}", attributes[attr]) }
      @resource_owner = owner
			@scope          ||= Doorkeeper.configuration.default_scope_string
      validate
    end

    def authorize
      if valid?
        create_access_token
      end
    end

    def authorization
      auth = {
        'access_token' => access_token.token,
        'token_type'   => access_token.token_type,
        'expires_in'   => access_token.expires_in,
      }
      auth.merge!({'refresh_token' => access_token.refresh_token}) if refresh_token_enabled?
      auth
    end

    def valid?
      self.error.nil?
    end

    def access_token
      @access_token
    end

    def token_type
      "bearer"
    end

    def error_response
      {
        'error' => error.to_s,
        'error_description' => error_description
      }
    end

    def client
      @client ||= Application.find_by_uid_and_secret(@client_id, @client_secret)
    end

    private

    def create_access_token
      @access_token = AccessToken.create!({
        :application_id    => client.id,
        :resource_owner_id => @resource_owner.id,
        :scopes            => @scope,
        :expires_in        => configuration.access_token_expires_in,
        :use_refresh_token => refresh_token_enabled?
      })
    end
    
    def refresh_token_enabled?
      configuration.refresh_token_enabled?
    end
    
    def has_scope?
      Doorkeeper.configuration.scopes.all.present?
    end

    def validate_attributes
      return false unless grant_type.present?
      username.present? && password.present?
    end

    def validate_grant_type
      %w(password).include? grant_type
    end

    def validate_client
      !!client
    end
    
    def validate_scope
      return true unless has_scope?
      ScopeChecker.valid?(scope, configuration.scopes)
    end

    def error_description
      I18n.translate error, :scope => [:doorkeeper, :errors, :messages]
    end

    def configuration
      Doorkeeper.configuration
    end
  end
end
