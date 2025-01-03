# frozen_string_literal: true

class Hospital < ApplicationRecord
  validates_presence_of :cnpj, :name
  validates_uniqueness_of :cnpj
  validates_inclusion_of :iss_prepaid, in: [ true, false ]
  validate :validate_cnpj

  has_many :locals, class_name: "HospitalLocal", dependent: :destroy

  scope :by_cnpj, ->(cnpj) { where(cnpj: cnpj) }
  scope :by_name, ->(name) { where("name ilike UPPER(?)", "%#{name.upcase}%") }

  before_save :prepare_cnpj
  before_destroy :validate_dependents

  def validate_cnpj
    errors.add(:cnpj, "inválido") unless CNPJ.valid?(self.cnpj)
  end

  def prepare_cnpj
    cnpj = CNPJ.new(self.cnpj)
    self.cnpj = cnpj.stripped
  end

  def validate_dependents
    return true if invoices.count == 0
    errors.add(:base, "Já existem notas emitidas para essa empresa")
    false
  end

  def full_address_nfse
    "#{address} #{address_number}, #{address_district}, CEP: #{address_zipcode}"
  end
end
