# frozen_string_literal: true

class InvoicePartnersController < BaseController
  def index
    @invoice_partners =
      if params[:status] == "authorized"
        InvoicePartner.authorized_payments(current_medical_organization_partner.id)
      elsif params[:status] == "release"
        InvoicePartner.open_payments(current_medical_organization_partner.id)
      else
        []
      end
  end

  def show
    @invoice_partner = InvoicePartner.where(medical_organization_partner_id: current_medical_organization_partner.id)
                                     .find(params[:id])
  end
end
