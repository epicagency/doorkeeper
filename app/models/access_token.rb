class AccessToken
  include Mongoid::Document
  include Mongoid::Timestamps
  include Doorkeeper::OAuth::RandomString
  include Doorkeeper::OAuth::Helpers

  store_in = :oauth_access_tokens

	field :resource_owner_id, :type => Hash  
  field :application_id, :type => Hash  
  field :token, :type => String
  field :refresh_token, :type => String
  field :expires_in, :type => Integer
	field :revoked_at, :type => DateTime
	field :scopes, :type => String

  belongs_to :application

  scope :accessible, where(:revoked_at => nil)

  validates :application_id, :resource_owner_id, :token, :presence => true

  attr_accessor :use_refresh_token

  before_validation :generate_token, :on => :create
  before_validation :generate_refresh_token, :on => :create, :if => :use_refresh_token?

  def self.authorized_for(application_id, resource_owner_id)
    accessible.where(:application_id => application_id, :resource_owner_id => resource_owner_id).first
  end

  def self.has_authorized_token_for?(application, resource_owner, scopes)
    token = accessible.
            where(:application_id => application.id,
                  :resource_owner_id => resource_owner.id).
            order("created_at desc").
            limit(1).
            first
    token && ScopeChecker.matches?(token.scopes, scopes)
  end

	def self.find_by_refresh_token(refresh_token)
    self.first(conditions: { refresh_token: refresh_token })
  end

	def self.find_by_token(token)
    self.first(conditions: { token: token })
  end
  
  def self.find_by_resource_owner_id(resource_owner_id)
    puts self.first(conditions: { resource_owner_id: resource_owner_id })
  end

  def token_type
    "bearer"
  end

  def revoke
    update_attribute :revoked_at, DateTime.now
  end

  def revoked?
    self.revoked_at.present?
  end

  def expired?
    expires_in.present? && Time.now > expired_time
  end

  def time_left
    time_left = (expired_time - Time.now)
    time_left > 0 ? time_left : 0
  end

  def accessible?
    !expired? && !revoked?
  end

  def scopes
    scope_string = self[:scopes] || ""
    scope_string.split(" ").map(&:to_sym)
  end

  def scopes_string
    self[:scopes]
  end

  def use_refresh_token?
    self.use_refresh_token
  end

  private

  def expired_time
    self.created_at + expires_in.seconds
  end

  def generate_refresh_token
    self.refresh_token = unique_random_string_for(:refresh_token)
  end

  def generate_token
    self.token = unique_random_string_for(:token)
  end
end
