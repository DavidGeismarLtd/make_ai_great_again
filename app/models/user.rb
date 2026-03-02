class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable, :confirmable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :trackable

  # Associations
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true, inclusion: { in: %w[user admin] }

  # Enums
  enum :role, { user: "user", admin: "admin" }

  # Set default role
  attribute :role, :string, default: "user"

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end
end
