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
    owner = authenticate_resource_owner! unless params['grant_type'].nil? or params['grant_type'] != 'password'
    @token ||= Doorkeeper::OAuth::AccessTokenRequest.new(params, )
  end
end
