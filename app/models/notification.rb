class Notification < ApplicationRecord
  belongs_to :medical_organization_partner

  scope :not_read, -> { where(read: false) }
end
