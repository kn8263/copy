class AttendancesController < ApplicationController
  before_action :set_user, only: %i(edit_one_month update_one_month)
  before_action :logged_in_user, only: %i(update edit_one_month)
  before_action :admin_or_correct_user, only: %i(update edit_one_month update_one_month)
  before_action :set_one_month, only: :edit_one_month
  before_action :admin_user_attendance_edit, only: %i(edit_one_month update_one_month)

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current)
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.rest_in_at.nil?
      if  @attendance.update_attributes(rest_in_at: Time.current)
        flash[:info] ="ゆっくり休憩してください。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.rest_out_at.nil?
      if  @attendance.update_attributes(rest_out_at: Time.current)
        flash[:info] ="休憩から上がりました。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current)
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
# 1 その日の総勤務時間を算出 ⬇️
    if @attendance.finished_at.present?
    # 退勤が0時過ぎの場合
      if @attendance.started_at > @attendance.finished_at
        @mid_night = ((@attendance.finished_at - @attendance.finished_at.change(hour: 0,min: 00, sec: 00)) /3600) #0時〜退勤までの勤務時間
        @night = ((@attendance.started_at.change(hour: 23, min: 59, sec: 59).round_to(15.minutes) - @attendance.started_at) /3600) #出勤〜24時までの勤務時間
        @total = @mid_night + @night #単純総勤務時間
      # 休憩の戻りが0時を過ぎた場合
        if @attendance.rest_in_at > @attendance.rest_out_at
          @mid_night_rest_out = ((@attendance.rest_out_at - @attendance.rest_out_at.change(hour: 0,min: 00, sec: 00)) /3600) # 0時〜休憩戻りの休憩時間
          @restin = ((@attendance.rest_in_at.change(hour:23 , min: 59, sec: 59).round_to(15.minutes) - @attendance.rest_in_at) /3600) # 休憩入り〜24時までの休憩時間
          @rest = @mid_night_rest_out + @restin # 休憩時間の合計
      # 休憩戻りが0時前の場合（日付が変わらない場合）もしくはどちらも深夜の休憩時間となった場合    
        else
          @rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600) 
        end
    # 勤怠情報がいずれも日を跨がない場合
      else
        # @total = @attendance.finished_at
        @total = ((@attendance.finished_at - @attendance.started_at) / 3600) 
        # @rest = @attendance.rest_out_at
        @rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600) 
      end
    # １日の総労働時間をわりだす
        @sum = (@total - @rest)
        @attendance.update_attributes(day_total_working: @sum )
    end
# 1 ⬆️    
    
# 2 その日の残業時間を算出 ⬇️    
    if @attendance.day_total_working.present?
      if @attendance.day_total_working > 8.0
        @day_over_working = (@attendance.day_total_working - 8.0)
      else
        @day_over_working = 0
      end
      @attendance.update_attributes(day_over_working: @day_over_working)
    end 
# 2 ⬆️


# 3 その日の深夜労働時間を算出 ⬇️
  # 3-1 退勤が日を跨がない場合 ⬇️
    if @attendance.finished_at.present? && @attendance.finished_at.hour >= 22
      @default = @attendance.finished_at.change(hour: 22, min: 00, sec: 00)
      # @night_work = (((@attendance.finished_at - @default).to_f) / 3600)   #　(　.to_f)
      @attendance.update_attributes(day_night_working: (((@attendance.finished_at - @default).to_f) / 3600))
    end
    
  # 3-1 ⬆️
  
  #3-2 出勤が22時前、退勤が日を跨いだ場合 ⬇️
    if @attendance.finished_at.present? && @attendance.finished_at.hour < @attendance.started_at.hour && @attendance.started_at.hour < 22
    # 退勤が6時を超えた場合デフォルトで8時間の深夜を労働時間となる
      if @attendance.finished_at.hour >= 6
        @mid_night = 6.0
        @night = 2.0
    # 退勤が6時を超えない場合0時から退勤までの時間と22-24時の深夜労働時間を足し合わせる
      else
        @default2 = @attendance.finished_at.change(hour: 0,min: 00, sec: 00)
        @mid_night = ((@attendance.finished_at - @default2) /3600)
        @night = 2.0
      end
      @night_total = @mid_night + @night
      
    # ⭐️1 休憩の入りが22時前且つ休憩の戻りが22-24時
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_in_at.hour < 22 && @attendance.rest_out_at.hour >= 22
        @default1 = @attendance.rest_out_at.change(hour: 22, min: 00, sec: 00)
        @night_rest = ((@attendance.rest_out_at - @default1) /3600)
      elsif @attendance.rest_out_at == @attendance.rest_in_at
        @night_rest = 0
      end
    # ⭐️2 休憩の入りが22-24時且つ休憩の戻りも22-24時
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_in_at.hour >= 22
        @night_rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
      end
    # ⭐️6 休憩の入りが22時前且つ休憩の戻りが日を跨いだ場合
      if @attendance.rest_out_at.hour < @attendance.rest_in_at.hour && @attendance.rest_in_at.hour < 22
        @default6 = @attendance.rest_out_at.change(hour: 0, min: 00, sec: 00)
        @night_rest = ((@attendance.rest_out_at - @default6) / 3600)
      end
    # ⭐️3 休憩の入りが22-24時且つ休憩の戻りが日を跨いだ場合
      if @attendance.rest_out_at.hour < @attendance.rest_in_at.hour && @attendance.rest_in_at.hour >= 22
        @default3_out = @attendance.rest_out_at.change(hour: 0,min: 00,sec: 00)
        @default3_in = @attendance.rest_in_at.change(hour:23, min:59, sec: 59).round_to(15.minutes)
        @mid_night_rest = ((@attendance.rest_out_at - @default3_out) / 3600)
        @night_late_rest = ((@default3_in - @attendance.rest_in_at) / 3600)
        @night_rest = @mid_night_rest + @night_late_rest
      end
    # ⭐️4 休憩の入り、戻り共に0時を過ぎた場合
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_out_at.hour <= 6 
        @night_rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
      end
    # ⭐️5 休憩の入りが0時を過ぎ、休憩の戻りが6時を過ぎた場合
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_out_at.hour >= 6 && @attendance.rest_in_at < 6
        @default5 = @attendance.rest_out_at.change(hour: 6, min: 00 , sec: 00)
        @rest_sum = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
        @rest_over = ((@attendance.rest_out_at - @default5) / 3600)
        @night_rest = @rest_sum - @rest_over
      end
      if @night_rest.nil? || @night_rest <= 0
        @night_rest = 0
      end
      @night_work = @night_total - @night_rest
      @attendance.update_attributes(day_night_working: @night_work)
  #3-2 ⬆️  
    
  #3-3 出勤が22時過ぎ、退勤が日を跨いだ場合 ⬇️
    elsif @attendance.finished_at.present? && @attendance.finished_at.hour < @attendance.started_at.hour  && @attendance.started_at.hour >= 22
      if @attendance.finished_at.hour >= 6
        @mid_night = 6.0
        @night_late = @attendance.started_at.change(hour: 23, min: 59, sec: 59).round_to(15.minutes)
        @night = ((@night_late - @attendance.started_at) /3600)
      else 
        @defa = @attendance.finished_at.change(hour: 0,min: 00, sec: 00)
        @mid_night = (((@attendance.finished_at - @defa).to_f) /3600)
        @night_late = @attendance.started_at.change(hour: 23, min: 59, sec: 59).round_to(15.minutes)
        @night = (((@night_late - @attendance.started_at).to_f) /3600)
      end
      @night_total = @mid_night + @night
      
      
    # ⭐️2 休憩の入りが22-24時且つ休憩の戻りも22-24時
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_in_at.hour >= 22
        @night_rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
      end
    # ⭐️3 休憩の入りが22-24時且つ休憩の戻りが日を跨いだ場合
      if @attendance.rest_out_at.hour < @attendance.rest_in_at.hour && @attendance.rest_in_at.hour >= 22
        @default3_out = @attendance.rest_out_at.change(hour: 0,min: 00,sec: 00)
        @default3_in = @attendance.rest_in_at.change(hour:23, min:59, sec: 59).round_to(15.minutes)
        @mid_night_rest = ((@attendance.rest_out_at - @default3_out) / 3600)
        @night_late_rest = ((@default3_in - @attendance.rest_in_at) / 3600)
        @night_rest = @mid_night_rest + @night_late_rest
      end
    # ⭐️4 休憩の入り、戻り共に0時を過ぎた場合
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_out_at.hour <= 6 
        @night_rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
      end
    # ⭐️5 休憩の入りが0時を過ぎ、休憩の戻りが6時を過ぎた場合
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_out_at.hour > 6 && @attendance.rest_in_at < 6
        @default5 = @attendance.rest_out_at.change(hour: 6, min: 00 , sec: 00)
        @rest_sum = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
        @rest_over = ((@attendance.rest_out_at - @default5) / 3600)
        @night_rest = @rest_sum - @rest_over
      end
      if @night_rest.nil?  || @night_rest <= 0
        @night_rest = 0
      end
      @night_work = @night_total - @night_rest
      @attendance.update_attributes(day_night_working: @night_work)
      
  #3-4 出勤が共に0時〜6時
    elsif @attendance.finished_at.present? && @attendance.finished_at > @attendance.started_at  && @attendance.started_at.hour < 6
      if @attendance.finished_at.hour >= 6
        @base = @attendance.finished_at.change(hour: 6, min: 00 , sec: 00)
        @night_sum = ((@attendance.finished_at - @attendance.started_at) / 3600)
        @night_over = ((@attendance.finished_at - @base) / 3600)
        @night_total = @night_sum - @night_over
      else 
        @night_total = ((@attendance.finished_at - @attendance.started_at) / 3600)
      end
      # ⭐️4 休憩の入り、戻り共に0時を過ぎた場合
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_out_at.hour <= 6 
        @night_rest = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
      end
    # ⭐️5 休憩の入りが0時を過ぎ、休憩の戻りが6時を過ぎた場合
      if @attendance.rest_out_at > @attendance.rest_in_at && @attendance.rest_out_at.hour > 6 && @attendance.rest_in_at < 6
        @default5 = @attendance.rest_out_at.change(hour: 6, min: 00 , sec: 00)
        @rest_sum = ((@attendance.rest_out_at - @attendance.rest_in_at) / 3600)
        @rest_over = ((@attendance.rest_out_at - @default5) / 3600)
        @night_rest = @rest_sum - @rest_over
      end
      if @night_rest.nil?  || @night_rest <= 0
        @night_rest = 0
      end
      @night_work = @night_total - @night_rest
      @attendance.update_attributes(day_night_working: @night_work)
    # else
      # @night_work = 0
      # @attendance.update_attributes(day_night_working: @night_work)
    end
    redirect_to @user
  end

  def edit_one_month
  end


     


  def update_one_month
  ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
        
        
        
        if attendance.finished_at.present?
          if attendance.finished_at < attendance.started_at
            mid_night = ((attendance.finished_at - attendance.finished_at.change(hour: 0,min: 00, sec: 00)) /3600)
            night = ((attendance.started_at.change(hour: 23, min: 59, sec: 59).round_to(15.minutes) - attendance.started_at) /3600)
            total = mid_night + night
            if attendance.rest_in_at > attendance.rest_out_at
              mid_night_rest_out = ((attendance.rest_out_at - attendance.rest_out_at.change(hour: 0,min: 00, sec: 00)) /3600)
              restin = ((attendance.rest_in_at.change(hour:23 , min: 59, sec: 59).round_to(15.minutes) - attendance.rest_in_at) /3600)
              rest = mid_night_rest_out + restin
            else
              rest = ((((attendance.rest_out_at - attendance.rest_in_at) / 60) / 60.0))
            end
            sum = total - rest
            item[:day_total_working] = sum
          else
            item[:day_total_working] = ((((attendance.finished_at - attendance.started_at) / 60) / 60.0) - (((attendance.rest_out_at - attendance.rest_in_at) / 60) / 60.0))
          end
          attendance.update_attributes!(item)
        end
        
        
   # 3 その日の深夜労働時間を算出 ⬇️
        # 3-1 退勤が日を跨がない場合 ⬇️
        if attendance.finished_at.present? && attendance.finished_at.hour >= 22
          default = attendance.finished_at.change(hour: 22, min: 00, sec: 00)
          item[:day_night_working] = (((attendance.finished_at - default).to_f) /3600)
          attendance.update_attributes!(item)
        # end
        # 3-1 ⬆️
        #3-2 出勤が22時前、退勤が日を跨いだ場合 ⬇️
        elsif attendance.finished_at.present? && attendance.finished_at.hour < attendance.started_at.hour && attendance.started_at.hour <= 21
          # 退勤が6時を超えた場合デフォルトで8時間の深夜を労働時間となる
          if attendance.finished_at.hour >= 6
            mid_night = 6.0
            night = 2.0
          # 退勤が6時を超えない場合0時から退勤までの時間と22-24時の深夜労働時間を足し合わせる
          elsif attendance.finished_at.hour < 6
            default2 = attendance.finished_at.change(hour: 0,min: 00, sec: 00)
            mid_night = (((attendance.finished_at - default2).to_f) /3600)
            night = 2.0
          end
          night_total = mid_night + night
            
        # ⭐️1 休憩の入りが22時前且つ休憩の戻りが22-24時
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_in_at.hour < 22 && attendance.rest_out_at.hour >= 22
            default1 = attendance.rest_out_at.change(hour: 22, min: 00, sec: 00)
            night_rest = (((attendance.rest_out_at - default1).to_f) /3600)
          elsif attendance.rest_out_at == attendance.rest_in_at
            night_rest = 0
          end
          
        # ⭐️2 休憩の入りが22-24時且つ休憩の戻りも22-24時
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_in_at.hour >= 22
            night_rest = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
          end
        # ⭐️6 休憩の入りが22時前且つ休憩の戻りが日を跨いだ場合
          if attendance.rest_out_at.hour < attendance.rest_in_at.hour && attendance.rest_in_at.hour < 22
            default6 = attendance.rest_out_at.change(hour: 0, min: 00, sec: 00)
            night_rest = (((attendance.rest_out_at - default6).to_f) / 3600)
          end
        # ⭐️3 休憩の入りが22-24時且つ休憩の戻りが日を跨いだ場合
          if attendance.rest_out_at.hour < attendance.rest_in_at.hour && attendance.rest_in_at.hour >= 22
            default3_out = attendance.rest_out_at.change(hour: 0,min: 00,sec: 00)
            default3_in = attendance.rest_in_at.change(hour:23, min:59, sec: 59).round_to(15.minutes)
            mid_night_rest = (((attendance.rest_out_at - default3_out).to_f) / 3600)
            night_late_rest = (((default3_in - attendance.rest_in_at).to_f) / 3600)
            night_rest = mid_night_rest + night_late_rest
          end
        # ⭐️4 休憩の入り、戻り共に0時を過ぎた場合
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_out_at.hour <= 6 
            night_rest = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
          end
        # ⭐️5 休憩の入りが0時を過ぎ、休憩の戻りが6時を過ぎた場合
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_out_at.hour >= 6 && attendance.rest_in_at < 6
            default5 = attendance.rest_out_at.change(hour: 6, min: 00 , sec: 00)
            rest_sum = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
            rest_over = (((attendance.rest_out_at - default5).to_f) / 3600)
            night_rest = rest_sum - rest_over
          end
          
          if night_rest.nil? || night_rest <= 0
            night_rest = 0
          end
          night_work = night_total - night_rest
          item[:day_night_working] = night_work
          attendance.update_attributes!(item)
        
      
          
    
        #3-3 出勤が22時過ぎ、退勤が日を跨いだ場合 ⬇️
        elsif attendance.finished_at.present? && attendance.finished_at.hour < attendance.started_at.hour  && attendance.started_at.hour >= 22
          if attendance.finished_at.hour >= 6
            mid_night = 6.0
            night_late = attendance.started_at.change(hour: 23, min: 59, sec: 59).round_to(15.minutes)
            night = (((night_late - attendance.started_at).to_f) /3600)
          elsif attendance.finished_at.hour < 6
            defa = attendance.finished_at.change(hour: 0,min: 00, sec: 00)
            mid_night = (((attendance.finished_at - defa).to_f) /3600)
            night_late = attendance.started_at.change(hour: 23, min: 59, sec: 59).round_to(15.minutes)
            night = (((night_late - attendance.started_at).to_f) /3600)
          end
          night_total = mid_night + night
      
          # ⭐️2 休憩の入りが22-24時且つ休憩の戻りも22-24時
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_in_at.hour >= 22
            night_rest = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
          end
          # ⭐️3 休憩の入りが22-24時且つ休憩の戻りが日を跨いだ場合
          if attendance.rest_out_at.hour < attendance.rest_in_at.hour && attendance.rest_in_at.hour >= 22
            default3_out = attendance.rest_out_at.change(hour: 0,min: 00,sec: 00)
            default3_in = attendance.rest_in_at.change(hour:23, min:59, sec: 59).round_to(15.minutes)
            mid_night_rest = (((attendance.rest_out_at - default3_out).to_f) / 3600)
            night_late_rest = (((default3_in - attendance.rest_in_at).to_f) / 3600)
            night_rest = mid_night_rest + night_late_rest
          end
          # ⭐️4 休憩の入り、戻り共に0時を過ぎた場合
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_out_at.hour <= 6 
            night_rest = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
          end
          # ⭐️5 休憩の入りが0時を過ぎ、休憩の戻りが6時を過ぎた場合
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_out_at.hour > 6 && attendance.rest_in_at.hour < 6
            default5 = attendance.rest_out_at.change(hour: 6, min: 00 , sec: 00)
            rest_sum = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
            rest_over = (((attendance.rest_out_at - default5).to_f) / 3600)
            night_rest = rest_sum - rest_over
          end
          
          if night_rest.nil? || night_rest <= 0
            night_rest = 0
          end
          
          night_work = night_total - night_rest
          item[:day_night_working] = night_work
          attendance.update_attributes!(item)
        # end
        #3-4 出勤が共に0時〜6時
        elsif attendance.finished_at.present? && attendance.finished_at > attendance.started_at && attendance.started_at.hour < 6
          if attendance.finished_at.hour >= 6
            base = attendance.finished_at.change(hour: 6, min: 00 , sec: 00)
            night_sum = (((attendance.finished_at - attendance.started_at).to_f) / 3600)
            night_over = (((attendance.finished_at - base).to_f) / 3600)
            night_total = night_sum - night_over
          elsif attendance.finished_at.hour < 6
            night_total = (((attendance.finished_at - attendance.started_at).to_f) / 3600)
          end
        # ⭐️4 休憩の入り、戻り共に0時を過ぎた場合
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_out_at.hour <= 6 
            night_rest = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
          end
        # ⭐️5 休憩の入りが0時を過ぎ、休憩の戻りが6時を過ぎた場合
          if attendance.rest_out_at > attendance.rest_in_at && attendance.rest_out_at.hour >= 6 && attendance.rest_in_at.hour < 6
            default5 = attendance.rest_out_at.change(hour: 6, min: 00 , sec: 00)
            rest_sum = (((attendance.rest_out_at - attendance.rest_in_at).to_f) / 3600)
            rest_over = (((attendance.rest_out_at - default5).to_f) / 3600)
            night_rest = rest_sum - rest_over
          end
          if night_rest.nil? || night_rest <= 0
            night_rest = 0
          end
          
          night_work = night_total - night_rest 
          item[:day_night_working] = night_work
          attendance.update_attributes!(item)
        else
          night_work = 0
          item[:day_night_working] = night_work
          attendance.update_attributes!(item)
        end
        
        
        
        if attendance.day_total_working.present? && attendance.day_total_working >= 8.0
          item[:day_over_working] = (attendance.day_total_working - 8.0)
          attendance.update_attributes!(item)
        else
          item[:day_over_working] = 0
          attendance.update_attributes!(item)
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end

  private
  
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :rest_in_at, :rest_out_at, :day_total_working, :day_regular_working, :day_over_working, :day_night_working, :note])[:attendances]
    end
    
    # beforeフィルター

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
    
    def admin_user_attendance_edit
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end
