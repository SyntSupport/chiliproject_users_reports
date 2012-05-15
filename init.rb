require 'redmine'
require 'active_support'

require File.dirname(__FILE__) + '/lib/mailer_patch.rb'

require 'dispatcher'
Dispatcher.to_prepare :chiliproject_users_reports do
  require_dependency 'mailer'
  Mailer.send(:include, UsersReports::Patches::MailerPatch)
end

Redmine::Plugin.register :chiliproject_users_reports do
  name 'Chiliproject Users Reports plugin'
  author 'Author name'
  description 'This is a plugin for ChiliProject'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :admin_menu, :edit_report, { :controller => 'watchman', :action => 'index' }, :caption => :menu_edit_report
  menu :account_menu, :view_reports, { :controller => 'report', :action => 'view' }, { :caption => :menu_view_reports, :first => true }
  menu :account_menu, :add_report, { :controller => 'report', :action => 'index' }, { :caption => :menu_add_report, :first => true }
end