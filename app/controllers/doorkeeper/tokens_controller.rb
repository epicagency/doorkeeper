class Doorkeeper::TokensController < Doorkeeper::ApplicationController

  before_filter :parse_client_info_from_basic_auth, :only => :create

  def create
    response.headers.merge!({
      'Pragma'        => 'no-cache',
      'Cache-Control' => 'no-store',
    })
    if token.authorize
      render :json => token.authorization
    else
      render :json => token.error_response, :status => :unauthorized
    end
  end

  private

  def token
    if params['grant_type'].nil? || params['grant_type'] != 'password'
      @token ||= Doorkeeper::OAuth::AccessTokenRequest.new(params)
    else
      owner = authenticate_resource_owner!
      @token ||= Doorkeeper::OAuth::PasswordAccessTokenRequest.new(owner, params)
    end
  end
end
