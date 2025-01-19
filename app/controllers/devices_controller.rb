# frozen_string_literal: true

class DevicesController < BaseController
  def create
    MedicalOrganizationPartnerDevice.create(
      medical_organization_partner: current_medical_organization_partner,
      device_id: params[:device_id],

    )

    render json: { success: true }
  end

  def destroy
    medical_organization_partner_device = MedicalOrganizationPartnerDevice.find_by(
      medical_organization_partner: current_medical_organization_partner,
      device_id: params[:id]
    )

    if medical_organization_partner_device
      medical_organization_partner_device.destroy
    end

    render json: { success: true }
  end
end
