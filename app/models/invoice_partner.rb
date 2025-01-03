# frozen_string_literal: true

class InvoicePartner < ApplicationRecord
  belongs_to :invoice, optional: :true
  belongs_to :medical_organization_partner
  belongs_to :payment, optional: :true

  validates_presence_of :original_value

  def self.authorized_payments(medical_organization_partner_id)
    joins(:invoice, :medical_organization_partner)
      .where(invoices: { status: :authorized })
      .where(medical_organization_partner_id: medical_organization_partner_id)
  end

  def self.open_payments(medical_organization_partner_id)
    joins(:invoice, :medical_organization_partner)
      .where(invoices: { status: :release })
      .where(status: :open)
      .where(medical_organization_partner_id: medical_organization_partner_id)
  end
end
