class DatasetsController < ApplicationController
  before_filter :authenticate_user!, except: :index
  before_filter :get_dataset, only: [:edit, :show, :update, :destroy]

  def get_dataset
    @dataset = Dataset.find(slug=params[:id])  # we are using slugs!
    rescue Mongoid::Errors::DocumentNotFound
      flash[:alert] = "The dataset you were looking for could not be found."
      redirect_to datasets_path
  end

  def index
    @datasets = Dataset.page params[:page]
  end

  def show
    if @dataset.data_extract
      gon.data_values = @dataset.data_extract['data_values']
      gon.headings_gon = @dataset.data_extract['headings']
      gon.chartTitle = @dataset.title
      gon.subTitle = @dataset.sub_title
      gon.yLabel = @dataset.y_label
      gon.xLabel = @dataset.x_label
    end
  end

  def new
    @dataset = Dataset.new
  end

  def create
    @dataset = Dataset.create dataset_params
    if @dataset.save
      # send file for processing
      _id = @dataset.id.to_s

      Resque.enqueue(
        ExcelToJson,
        _id,
        dataset_params['attachment'].tempfile.path,
        dataset_params['chart_type'],
        @dataset.attachment.path.split("/").last)

      redirect_to @dataset, notice: "You have successfully uploaded a dataset"
    else
      flash[:alert] = "The dataset you have could not be uploaded."
      render "new"
    end
  end

  def edit
  end

  def update
    if @dataset.update_attributes dataset_params
      _id = @dataset.id.to_s
      # TODO refactor and put this in dataset.rb
      Resque.enqueue(
        ExcelToJson,
        _id,
        dataset_params['attachment'].tempfile.path,
        dataset_params['chart_type'],
        @dataset.attachment.path.split("/").last)
      redirect_to @dataset, notice: "You have successfully updated this dataset."
    else
      render "edit"
    end
  end

  def destroy
  end

  private
    def dataset_params
      params.require(:dataset).permit(
        :name,
        :description,
        :attachment,
        :chart_type,
        :x_label,
        :y_label,
        :sub_title,
        :title,
        :data_units)
    end

end
