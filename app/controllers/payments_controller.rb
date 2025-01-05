# frozen_string_literal: true


class PaymentsController < BaseController
  def index
    @payments = Payment.where(medical_organization_partner_id: current_medical_organization_partner.id).order("payment_date desc")
  end

  def show
    @payment = Payment.find(params[:id])
  end
end
