class ArchivesController < ApplicationController
  before_action :require_login

  def index
    months = current_user.pays.record_months
    years = months.map(&:year).uniq

    @year = year_from(params[:year])
    @months = months.select { |month| month.year == @year }
    @previous_year = years.select { |year| year < @year }.max
    @next_year = years.select { |year| year > @year }.min
  end

  private
    # "2025" のような文字列を、整数の年にする。不正な値なら、今年にする
    def year_from(value)
      year = Integer(value, exception: false)
      year&.between?(1, 9999) ? year : Date.current.year
    end
end
