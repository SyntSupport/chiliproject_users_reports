module UsersReports
  module Patches
    module MailerPatch
      def self.included(base)
        #base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def report_notification(report, recipient_id)
          @recipient = User.find(recipient_id)
          #@report = report
          recipients @recipient.mail
          subject "Report: " + User.find(report.user_id).name + ", " + report.report_date.strftime("%Y/%m/%d")
          body :url => url_for(:controller => 'report', :action => 'show', :report => report.id ),
               :report => report
          render_multipart('report_notification', body)
        end
      end
    end
  end
end
