class MedicalOrganizationPartner < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates_presence_of :cpf, :name, :email, :free_bank_transfer, :fees, :taxes, :bank_code, :bank_account, :bank_agency
  validates_numericality_of :fees, greater_than: 0
  validates_numericality_of :taxes, greater_than: 0
  # validates_email_format_of :email
  validates_uniqueness_of :cpf, scope: :medical_organization_id

  # belongs_to :medical_organization
  # belongs_to :bank, class_name: "Bank", foreign_key: "bank_code", primary_key: "code", optional: true
  # has_many :payments
  # has_many :invoice_partners

  scope :by_medical_organization, ->(medical_organization_id) { where(medical_organization_id: medical_organization_id) }
  scope :by_cpf, ->(cpf) { where(cpf: cpf) }
  scope :by_name, ->(name) { where("name ilike UPPER(?)", "%#{name.upcase}%") }
  scope :only_actives, -> { where(active: true) }

  before_destroy :validate_dependents

  def validate_dependents
    return true if invoice_partners.count == 0
    errors.add(:base, "Já existem notas emitidas para esse profissional")
    false
  end
end
