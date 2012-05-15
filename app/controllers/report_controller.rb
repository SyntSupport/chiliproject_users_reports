class ReportController < ApplicationController
  unloadable

  def index
    
    #    if params.key?(:errors)
    #      @errors = params[:errors]
    #    end
    #собрать массив за последние 7 дней, где одна запись (дата с днем недели, отчет, признак барахла)
    duration = 6
    row_reports = Report.find(:all, :conditions => { :user_id => User.current.id, :report_date => (Time.now - duration.days).beginning_of_day..Time.now }, :order => "report_date DESC")
    
    @reports = []
    (0..duration).each do |i|
      onedayreps = row_reports.select {|report| report.report_date >= (Time.now - i.days).beginning_of_day and report.report_date <= (Time.now - i.days).end_of_day}
      if onedayreps.blank?
        onedayreps = [Report.new({:report_date => (Time.now - i.days).beginning_of_day, :user_id => User.current.id})]
      end
      @reports.concat(onedayreps)
    end
  end

  def addrep    
    if params[:report][:id] == ""
      @report = Report.new(params[:report])
      @report.user_id = User.current.id
    else
      @report = Report.find(params[:report][:id])
      if @report.user_id != User.current.id
        @report.manager_id = User.current.id
      end
      @report.attributes= params[:report]
    end

    if @report.save
      @report.send_notifications
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = @report.errors.full_messages
    end
    if (/show\?report=/.match(request.env["HTTP_REFERER"]))
        redirect_to :action => 'view'
      else
        redirect_to :action => 'index'
      end
  end

  def view
    #для этого пользователя получить всех кого он смотрит, отсортированных по ид, влючить себя первым
    #выбрать все записи за n дней для этих пользователей
    duration = 6
    @WATCHEDIDS = Watchman.getwatchedids
    if (params.key?(:filter))
      @watchedids = (params[:filter].key?(:watched_id) ? params[:filter][:watched_id].collect { |i| i.to_i  } : @WATCHEDIDS)
      endtime = Time.parse(params[:filter][:enddate]) rescue Time.now
      starttime = Time.parse(params[:filter][:startdate]) rescue (endtime - duration.days).beginning_of_day
    else
      @watchedids = @WATCHEDIDS
      starttime = (Time.now - duration.days).beginning_of_day
      endtime = Time.now
    end
    duration = ((endtime-starttime)/1.days).to_i
    row_reports = Report.find(:all, :conditions => { :user_id => @watchedids, :report_date => starttime..endtime }, :order => "report_date DESC")
    #создать хеш, где ключами будут ид пользователей, а значениями массив отчетов, причем индекс в массиве будет означать кол-во дней назад от стартовой (или текущей даты)
    @id_and_reps = Hash.new
    @watchedids.each do |id|
      reports = []
      (0..duration).each do |i|
        onedayreps = row_reports.select {|report| report.user_id == id and report.report_date >= (endtime - i.days).beginning_of_day and report.report_date <= (endtime - i.days).end_of_day}
        if onedayreps.blank?
          onedayreps = [Report.new({:report_date => (Time.now - i.days).beginning_of_day, :user_id => User.current.id})]
        end
        reports.concat(onedayreps)
      end
      @id_and_reps[id] = reports
    end
    #@id_and_reps.each { |k,v| puts "#{k}: #{v}" }
  end

  def show
    @report = Report.find(params[:report]) rescue nil
    if @report.nil?
      render_404
      return false
    end
    unless Watchman.getwatchedids.include? @report.user.id
      render_403
      return false
    end
  end

#  def update_view
#    #для этого пользователя получить всех кого он смотрит, отсортированных по ид, влючить себя первым
#    #выбрать все записи за n дней для этих пользователей
#    @WATCHEDIDS = Watchman.getwatchedids
#    if (params.key?(:filter))
#      @watchedids = (params[:filter].key?(:watched_id) ? params[:filter][:watched_id].collect { |i| i.to_i  } : @WATCHEDIDS)
#      endtime = Time.parse(params[:filter][:enddate]) rescue Time.now
#      starttime = Time.parse(params[:filter][:startdate]) rescue (endtime - 2.days).beginning_of_day
#    else
#      @watchedids = @WATCHEDIDS
#      starttime = (Time.now - 2.days).beginning_of_day
#      endtime = Time.now
#    end
#    duration = ((endtime-starttime)/1.days).to_i
#    row_reports = Report.find(:all, :conditions => { :user_id => @watchedids, :report_date => starttime..endtime }, :order => "report_date DESC")
#    #создать хеш, где ключами будут ид пользователей, а значениями массив отчетов, причем индекс в массиве будет означать кол-во дней назад от стартовой (или текущей даты)
#    @id_and_reps = Hash.new
#    @watchedids.each do |id|
#      #      if w_id.is_a? Watchman
#      #        id = w_id.watched_id
#      #      else
#      #        id = w_id
#      #      end
#      #puts "ilya_" + id.to_s
#      reports = []
#      (0..duration).each do |i|
#        onedayreps = row_reports.select {|report| report.user_id == id and report.report_date >= (endtime - i.days).beginning_of_day and report.report_date <= (endtime - i.days).end_of_day}
#        if onedayreps.blank?
#          onedayreps = [Report.new({:report_date => (Time.now - i.days).beginning_of_day, :user_id => User.current.id})]
#        end
#        reports.concat(onedayreps)
#      end
#      @id_and_reps[id] = reports
#    end
#    #@id_and_reps.each { |k,v| puts "#{k}: #{v}" }
#  end
end

