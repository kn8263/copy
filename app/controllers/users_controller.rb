require 'csv'

class UsersController < ApplicationController
  before_action :set_user, only: %i(show edit update destroy edit_basic_info update_basic_info)
  before_action :logged_in_user, only: %i(index destroy edit_basic_info update_basic_info)
  before_action :admin_user, only: %i(edit update destroy edit_basic_info update_basic_info index)
  before_action :set_one_month, only: :show

  

  def index
    @users = User.paginate(page: params[:page], per_page: 20).search(params[:search]).order(:emp_id).includes(:attendances)
    # @users = User.all.includes(:attendances)
  end
  
  
  def csv_user_attendance
    head :no_content
    bom = "\uFEFF"
    
    # attendances = Attendance.all
    users = User.all.includes(:attendances).order(:emp_id)
    
      year = params["worked_on(1i)"].to_i
      month = params["worked_on(2i)"].to_i
      day = params["worked_on(3i)"].to_i
      @date = Date.new(year,month,day)
    
      @csv_first_day = @date.beginning_of_month
      @csv_last_day = @csv_first_day.end_of_month
    
    filename = @csv_first_day.strftime("%Y年%m月") + "勤怠集計データ" 
    
    csv1 = CSV.generate(bom) do |csv|
      columns = ["社員コード", "社員氏名", "タイムカード年月", "勤務日数", "欠勤日数", "有給日数", "勤務時間", "残業時間", "深夜労働時間", "早出時間", "延長時間", "休日出勤時間1", "休日残業時間1", "休日深夜労働時間1", "休日出勤時間2", "休日残業時間2", "休日深夜労働時間2", "45-60時間残業時間", "60越残業時間", "遅刻早退時間", "有給時間"]
      csv << columns
        
      users.each do |userrow|
        attendances = Attendance.where(user_id: userrow.id , worked_on: @csv_first_day..@csv_last_day)
        workdaysum = attendances.where.not(started_at: nil).count #勤務日数
        timecard = @csv_first_day.strftime("%Y/%m") #タイムカード年月
        absence = 0 #欠勤日数
        paid_off = 0 #有給日数
        early_work = 0 #早出
        extention = 0 #延長
        holiday_work1 = 0 #休日出勤1
        holiday_over_work1 = 0 #休日残業1
        holiday_night_work1 = 0 #休日深夜1
        holiday_work2 = 0 #休日出勤2
        holiday_over_work2 = 0 #休日残業2
        holiday_night_work2 = 0 #休日深夜2
        over45to60h_work = 0 #４０−６０時間残業
        over60h_over_work = 0 #60時間超残業
        late_or_leave_early = 0 #遅刻早退時間
        paid_off_hour = 0 #有給時間
        
        monthly_total_working = 0
        monthly_over_working = 0
        monthly_night_working = 0
        attendances.each do |attendance|
          unless attendance.day_total_working.nil?
            monthly_total_working += attendance.day_total_working
          end 
          unless attendance.day_over_working.nil?
            monthly_over_working += attendance.day_over_working
          end
          unless attendance.day_night_working.nil?
            monthly_night_working += attendance.day_night_working
          end  
        end
        
        mtwh = monthly_total_working.truncate
        mtwm = ((monthly_total_working - mtwh) * 60 ).round
     # 分の表記部分を１桁の場合０を加えて"03"のように表記する
        if mtwm.to_s.length <= 1
          mtwm = "0" + mtwm.to_s
        end
        monthly_total_working = mtwh.to_s + ":"  + mtwm.to_s + ":" + "00"
        
        monthly_over_working = monthly_over_working.round(2)
        
        
        mnwh = monthly_night_working.truncate
        mnwm = ((monthly_night_working - mnwh) * 60 ).round
        if mnwm.to_s.length <= 1
          mnwm = "0" + mnwm.to_s
        end
        monthly_night_working = mnwh.to_s + ":"  + mnwm.to_s + ":" + "00"
        
        
        outputCsvRow = []	
        outputCsvRow = {
          userid: userrow.emp_id,
          username: userrow.name,
          tc: timecard,
          ws: workdaysum,
          ab: absence,
          po: paid_off,
          mtw: monthly_total_working,
          mow: monthly_over_working,
          mnw: monthly_night_working,
          ew: early_work,
          ex: extention,
          hw1: holiday_work1,
          how1: holiday_over_work1,
          hnw1: holiday_night_work1,
          hw2: holiday_work2,
          how2: holiday_over_work2,
          hnw2: holiday_night_work2,
          over45: over45to60h_work,
          over60: over60h_over_work,
          l_or_le: late_or_leave_early,
          poh: paid_off_hour
        }	
        csv << outputCsvRow.values_at(
          :userid,
          :username,
          :tc,
          :ws,
          :ab,
          :po,
          :mtw,
          :mow,
          :mnw,
          :ew,
          :ex,
          :hw1,
          :how1,
          :hnw1,
          :hw2,
          :how2,
          :hnw2,
          :over45,
          :over60,
          :l_or_le,
          :poh
          )
      end
    end
    create_csv(filename, csv1)
  end
  
  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "情報を更新しました。"
      redirect_to @user
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :department, :password, :password_confirmation, :emp_id, :position, :bikou, :hour_pay, :tp_ex)
    end

    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time, :position, :bikou, :hour_pay, :tp_ex, :emp_id)
    end
    
    
    
    def create_csv(filename, csv1)
      File.open("./#{filename}.csv", "w") do |file|
        file.write(csv1)
      end
      
      stat = File::stat("./#{filename}.csv")
      send_file("./#{filename}.csv", filename: "#{filename}.csv", length: stat.size)
    end
        
end