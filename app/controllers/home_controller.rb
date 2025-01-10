# frozen_string_literal: true

class HomeController < BaseController
  def index
    @authorized_count = InvoicePartner.authorized_payments(current_medical_organization_partner.id).count
    @authorized_value = InvoicePartner.authorized_payments(current_medical_organization_partner.id).sum(:value)

    @release_count = InvoicePartner.open_payments(current_medical_organization_partner.id).count
    @release_value = InvoicePartner.open_payments(current_medical_organization_partner.id).sum(:value)

    start_date = (Time.current - 11.month).beginning_of_month
    end_date = Time.current.end_of_month
    @payments = Payment.total_by_month(current_medical_organization_partner.id)
  end
end
