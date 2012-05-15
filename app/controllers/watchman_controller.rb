class WatchmanController < ApplicationController
  unloadable

  before_filter :admin?, :only => :index

  def index
    @users = User.find(:all, :order => :lastname, :conditions => "status = 1")
    @watch_pairs = Watchman.find(:all, :order => "watchman_id")
  end
  
  def create
    @newwatchpair = Watchman.new
    @newwatchpair.watchman  = params[:watchman][:watchman_id].blank? ? nil : User.find(params[:watchman][:watchman_id])
    @newwatchpair.watched =  params[:watchman][:watched_id].blank? ? nil : User.find(params[:watchman][:watched_id])
    if @newwatchpair.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = @newwatchpair.errors.full_messages.join(", ")
    end
    redirect_to :action => 'index'
  end

  def delete
    Watchman.find(params[:pair][:id]).destroy
    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'index'
  rescue
    redirect_to :action => 'index'
  end

  def admin?
    unless User.current.admin?
      render_403
    end
  end
end

