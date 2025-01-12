# fronzen_string_literal: true

class NotificationsController < BaseController
  def index
    @notifications = current_medical_organization_partner.notifications.not_read.order("created_at desc")
  end

  def show
    @notification = current_medical_organization_partner.notifications.find(params[:id])
  end
end
