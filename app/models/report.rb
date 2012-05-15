class Report < ActiveRecord::Base
  unloadable
  belongs_to :user
  belongs_to :manager, :class_name => "User"
  validates_presence_of :report_date, :user_id, :report, :on => :save
  validates_uniqueness_of :report_date, :scope => :user_id

  def send_notifications
    recipients = []
    if self.user_id == User.current.id
      recipients = Watchman.getwatchmanids
    else
      recipients << self.user_id << User.current.id
    end
    recipients.each do |recipient_id|
      Mailer.deliver_report_notification(self, recipient_id)
    end
  end
end
