class Report < ActiveRecord::Base
  unloadable
  belongs_to :user
  belongs_to :manager, :class_name => "User"
  validates_presence_of :report_date, :user_id, :report, :on => :save
  validates_uniqueness_of :report_date, :scope => :user_id

  def send_notifications(subj)
    #logger.debug "IN send_notifications"
    recipients = []
    if self.user_id == User.current.id
      recipients = Watchman.getwatchmanids - [User.current.id]
    else
      recipients << self.user_id
    end
    recipients.each do |recipient_id|
      #logger.debug "IN recipient: " + recipient_id.to_s
      Mailer.deliver_report_notification(self, recipient_id, subj)
    end
  end
end