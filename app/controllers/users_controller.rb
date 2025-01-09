# frozen_string_literal: true

class UsersController < BaseController
  def edit
    @user = current_medical_organization_partner
  end

  def update
    @user = current_medical_organization_partner
    @user.assign_attributes(user_params)
    if @user.save
      redirect_to root_path(@user), notice: "Configurações salvas com sucesso!"
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:medical_organization_partner).permit(:payment_type, :pix, :bank_code, :bank_agency, :bank_account)
  end
end
