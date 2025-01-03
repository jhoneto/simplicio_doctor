# frozen_string_literal: true

class HomeController < BaseController
  def index
    @authorized_count = InvoicePartner.authorized_payments(current_medical_organization_partner.id).count
    @authorized_value = InvoicePartner.authorized_payments(current_medical_organization_partner.id).sum(:value)

    @release_count = InvoicePartner.open_payments(current_medical_organization_partner.id).count
    @release_value = InvoicePartner.open_payments(current_medical_organization_partner.id).sum(:value)
  end
end
