# fronzen_string_literal: true

class NotificationsController < BaseController
  def index
    @notifications = current_medical_organization_partner.notifications.order("created_at desc")
    @notifications = @notifications.unread if params[:filter].to_sym == :unread
  end

  def show
    @notification = current_medical_organization_partner.notifications.find(params[:id])
    @notification.read!
  end
end
