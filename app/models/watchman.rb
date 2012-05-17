class Watchman < ActiveRecord::Base
  unloadable
  belongs_to :watchman, :class_name => "User"
  belongs_to :watched, :class_name => "User"
  validates_presence_of :watchman_id, :watched_id, :on => :save
  validates_uniqueness_of :watched_id, :scope => :watchman_id

  def self.getwatchedids
    ids = []
#    if User.current.admin?
#      watcheds = User.find(:all, :conditions => "status = 1", :order => :lastname )
#      watcheds.each do |w|
#        ids << w.id
#      end
#    else
      watcheds = Watchman.find_by_sql("SELECT distinct watched_id FROM watchmen where watchman_id = " + User.current.id.to_s + " and watched_id <>  " + User.current.id.to_s + " order by watched_id")
      watcheds.each do |w|
        ids << w.watched_id
      end
      ids.insert(0,User.current.id)
#    end
    return ids
  end
  def self.getwatchmanids
    watchmans = Watchman.find_by_sql("SELECT distinct watchman_id FROM watchmen where watched_id = " + User.current.id.to_s + " and watchman_id <>  " + User.current.id.to_s)
    ids = []
    watchmans.each do |w|
      ids << w.watchman_id
    end
    ids.insert(0,User.current.id)
  end
end
