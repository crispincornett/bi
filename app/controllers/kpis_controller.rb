class KpisController < ApplicationController
  skip_before_filter :require_user, :only => [:index, :show, :tags]

  def create
    @kpi = Kpi.new(params[:kpi])
    if @kpi.save
      flash[:success] = "Kpi Added"
      redirect_to kpi_path(@kpi)
    else
      redirect_to new_kpi_path
    end
  end

  def new
    @kpi = Kpi.new
  end

  def index
    @tags = Kpi.tag_counts_on(:tags)
    @kpis = Kpi.paginate(:page => params[:page])
  end

  def search
    @kpis = Kpi.basic_search(params[:search][:search_term]).paginate(:page => params[:page])
  end

  def show
    @kpi = Kpi.find(params[:id])
    @start_date = params[:start_date] || Time.now.weeks_ago(4).to_date
    @end_date = params[:end_date] || Time.now.yesterday.to_date
    @results = @kpi.results_between_dates(@start_date, @end_date)
    respond_to do |format|
      format.html
      format.json { render :json => @results }
    end
  end

  def edit
    @kpi = Kpi.find(params[:id])
  end

  def update
    @kpi = Kpi.find(params[:id])
    if @kpi.update_attributes(params[:kpi])
      flash[:success] = "Kpi updated"
      redirect_to kpi_path(@kpi)
    else
      render 'edit'
    end
  end

  def kpi_menu
  end

  def add_categorization
    @kpi = Kpi.find(params[:id])
    @category = KpiCategory.find_by_name(params[:category])
    KpiCategorization.create!(:kpi_id => @kpi.id, :kpi_category_id => @category.id, :name => @kpi.name, :sort_order => 1, :category => @category.name)
    redirect_to edit_kpi_path(@kpi)
  end

  def stats
    @date = params[:date].present? ? params[:date] : Time.now.yesterday.to_date
    @tag = params[:tag] || "Totals"
    @stats = Kpi.results_for_tag_and_date(@tag, @date)
    if @stats.count > 0
      @stats.sort_by!{|s| s.kpi.name }
    end
  end

  def destroy
  end


  def tags
    @kpis = Kpi.tagged_with(params[:tag]).paginate(:page => params[:page])
    @tag = params[:tag]
    respond_to do |format|
      format.html
      format.json { render :json => @kpis.map(&:most_recent_result) }
    end
  end

  def add_tag
    @kpi = Kpi.find(params[:id])
    @tag = params[:tag]
    @kpi.tag_list.add(@tag)
    @kpi.save
  end


end
