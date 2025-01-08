class UpdatePassword < ActiveRecord::Migration[7.2]
  def change
    MedicalOrganizationPartner.all.each do |medical_organization_partner|
      medical_organization_partner.password = medical_organization_partner.cpf.gsub(/\D/, '')
      medical_organization_partner.save
    end
  end
end
