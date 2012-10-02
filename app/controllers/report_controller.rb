class ReportController < ApplicationController
  unloadable

  #выводит список незаполненных отчетов
  def index
    #собрать массив за последние 7 дней, где одна запись (дата с днем недели, отчет, признак барахла)
    duration = 6
    if (params.key?(:filter))
      endtime = Time.parse(params[:filter][:enddate]) rescue Time.now
      starttime = Time.parse(params[:filter][:startdate]) rescue (endtime - duration.days).beginning_of_day
    else
      starttime = (Time.now - duration.days).beginning_of_day
      endtime = Time.now
    end
    duration = ((endtime-starttime)/1.days).to_i
    if duration > 30
      duration = 30
      starttime = (endtime - duration.days).beginning_of_day
    elsif duration < 0
      duration = 0
      starttime = (endtime - duration.days).beginning_of_day
    end
    @startdate = starttime.strftime("%Y-%m-%d")
    @enddate = endtime.strftime("%Y-%m-%d")
    row_reports = Report.find(:all, :conditions => { :user_id => User.current.id, :report_date => starttime..endtime }, :order => "report_date DESC")
    #для каждого дня: если нет отчета - сделать заготовку
    @reports = []
    (0..duration).each do |i|
      onedayreps = row_reports.select {|report| report.report_date >= (endtime - i.days).beginning_of_day and report.report_date <= (endtime - i.days).end_of_day}
      if onedayreps.blank?
        onedayreps = [Report.new({:report_date => (endtime - i.days).beginning_of_day, :user_id => User.current.id})]
      end
      @reports.concat(onedayreps)
    end
  end

  #добавление, обновление отчетов
  def add
    reports = params[:reports][:report] #список всех отчетов с возможными обновлениями
    errors = "" #список ошибок
    glue = ", " #связка между ошибками
    isupdate = false #было ли обновления событий или просто нажата кнопка обновить
    reports.each_value do |report|
      if report[:id] == "" #новый отчет
        if report[:report] == "" #поле отчета не заполнено
          next
        end
        @report = Report.new(report)
        @report.user_id = User.current.id
        status = l(:new_report) #для темы письма-уведомления
      else
        @report = Report.find(report[:id])
        #унифицирование значений
        rep  = (@report.report.nil? ? "" : @report.report)
        comment = (@report.comment.nil? ? "" : @report.comment)
        trash_db = (@report.trash.nil? ? false : @report.trash)
        trash = (report[:trash] == "0" ? false : true)
        #были ли обновления
        if @report.user_id != User.current.id #свой отчет или ты менеджер
#          logger.debug "@report.comment: " +  comment
#          logger.debug "report[:comment]: " + report[:comment]
#          logger.debug "@report.comment == report[:comment]: " + (comment == report[:comment]).to_s
#          logger.debug "@report.trash: " + trash_db.to_s
#          logger.debug "report[:trash]: " + trash.to_s
#          logger.debug "@report.trash == report[:trash]: " + (trash_db == trash).to_s
          if comment == report[:comment] && trash_db == trash
            next
          end
          if trash == true
            status = l(:redo_report) #для темы письма-уведомления
          elsif trash_db != trash
            status = l(:accepted_report) #для темы письма-уведомления
          else
            status = l(:comment_report) #для темы письма-уведомления
          end
          @report.manager_id = User.current.id
        else
          #logger.debug "@report.report: " + rep
          #logger.debug "report[:report]: " + report[:report]
          #logger.debug "@report.report == report[:report]: " + (rep == report[:report]).to_s
          if rep == report[:report]
            next
          end
          status = l(:redid_report) #для темы письма-уведомления
          @report.trash = false
        end
        @report.attributes= report
      end
      isupdate = true
      if @report.save
        @report.send_notifications(status) #рассылка уведомлений
      else
        errors << report[:report_date] + ": " + @report.errors.full_messages.inspect + glue
      end
    end
    if isupdate == true
      if errors == ""
        flash[:notice] = l(:notice_successful_update)
      else
        flash[:error] = errors[0..-(glue.length+1)]
      end
    else
      flash[:error] = l(:nothing_to_update)
    end
    if (/report\/show/.match(request.env["HTTP_REFERER"]))
      if !params.key?(:filter) || errors != ""
        if (@report.nil? || @report.id.nil?)
          redirect_to :action => 'show', :report => { :id => "", :report_date => reports.first[1][:report_date], :user_id => reports.first[1][:user_id] }
        else
          redirect_to :action => 'show', :report => @report.id
        end
      else
        redirect_to :action => 'view', :filter => { :startdate => params[:filter][:startdate], :enddate => params[:filter][:enddate], :watched_id =>
            params[:filter][:watched_id].split(/[,\[]/).select{|i| i != ""}.collect{|i| i.to_i}}
      end
    else
      redirect_to :action => 'index'
    end
  end

  #просмотр отчетов за период времени
  def view
    #для этого пользователя получить всех кого он смотрит, отсортированных по ид, влючить себя первым
    #выбрать все записи за n дней для этих пользователей
    duration = 6
    @selected = Watchman.getwatchedids #выбранные для просмотра по умолчанию
    @all = User.current.admin? ? User.active.collect{|u| u.id} : @selected #если ты админ, то смотреть можешь всех
    @all = @all.sort{|a,b| User.find(a).lastname <=> User.find(b).lastname } #сортировка списка наблюдаемых по фамилии
    if (params.key?(:filter))
      @watchedids = (params[:filter].key?(:watched_id) ? params[:filter][:watched_id].collect { |i| i.to_i  } : @selected)
      endtime = Time.parse(params[:filter][:enddate]) rescue Time.now
      starttime = Time.parse(params[:filter][:startdate]) rescue (endtime - duration.days).beginning_of_day
      @selected = @watchedids
    else
      @watchedids = @selected
      starttime = (Time.now - duration.days).beginning_of_day
      endtime = Time.now
    end
    @watchedids.sort!{|a,b| User.find(a).lastname <=> User.find(b).lastname } #сортировка столбцов по фамилиям
    if (@watchedids.include?(User.current.id))
      @watchedids = (@watchedids - [User.current.id]).insert(0,User.current.id) #если текущий юзер есть в списке, то он должен идти первым
    end
    duration = ((endtime-starttime)/1.days).to_i
    if duration > 30
      duration = 30
      starttime = (endtime - duration.days).beginning_of_day
    elsif duration < 0
      duration = 0
      starttime = (endtime - duration.days).beginning_of_day
    end
    @startdate = starttime.strftime("%Y-%m-%d")
    @enddate = endtime.strftime("%Y-%m-%d")
    row_reports = Report.find(:all, :conditions => { :user_id => @watchedids, :report_date => starttime..endtime }, :order => "report_date DESC")
    #создать хеш, где ключами будут ид пользователей, а значениями массив отчетов, причем индекс в массиве будет означать кол-во дней назад от стартовой (или текущей даты)
    @id_and_reps = Hash.new
    @watchedids.each do |id|
      reports = []
      (0..duration).each do |i|
        onedayreps = row_reports.select {|report| report.user_id == id and report.report_date >= (endtime - i.days).beginning_of_day and report.report_date <= (endtime - i.days).end_of_day}
        if onedayreps.blank?
          onedayreps = [Report.new({:report_date => (endtime - i.days).beginning_of_day, :user_id => User.current.id})]
        end
        reports.concat(onedayreps)
      end
      @id_and_reps[id] = reports
    end
    #@id_and_reps.each { |k,v| puts "#{k}: #{v}" }
  end

  #показ отдельного отчета
  def show
    if (params[:report].key?(:id) rescue false)
      if params[:report][:id] == ""
        @report = Report.new(params[:report])
      else
        @report = Report.find(params[:report][:id]) rescue nil
      end
    else
      @report = Report.find(params[:report]) rescue nil
    end
    if @report.nil? || (@report.id.nil? && @report.user_id != User.current.id)
      render_404
      return false
    else
      unless Watchman.getwatchedids.include?(@report.user_id) || (!@report.id.nil? && User.current.admin?)
        render_403
        return false
      end
    end
  end
end

