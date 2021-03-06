class PagesController < ApplicationController
  before_action :authenticate_user!, only: :activity

  def index
    @recent_datasets = Dataset.order("created_at DESC").scoped limit: 3
    @recent_documents = Document.scoped limit: 5

    _tags = Dataset.all.collect(&:tags).reject!(&:empty?)
    # cleanup
    @tags = []
    if !_tags.nil?
      _tags.each do |tag|
        _tag_split = tag.split(',')
        _tag_split.each do |_tagged|
          @tags << _tagged
        end
      end
    end
    # sanitize (only unique tags)
    @tags.uniq!

    if params[:search].nil?
      @datasets = Dataset.scoped limit: 10
    else
      @datasets = Dataset.search(params[:search]).delete_if { |x| x.empty? or x.nil? }
    end
  end

  def about
  end

  def admin
    @dataset_count = Dataset.count
    @dataset_view = Dataset.all.inject(0) { |result, element| result + element.view_count }
    @user_count = User.count
    @document_count = Document.count
    @unapproved_count = OpenWorkspace.where(approved: false).count
    @unapproved_datasets_count = Dataset.where(approved: false).count
  end

  def developer
  end

  def activity
    @activities = PublicActivity::Activity.all  # TODO -> paginate
  end

end
