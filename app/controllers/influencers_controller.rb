class InfluencersController < ApplicationController
  def index
    @influencers = Influencer.all.page(params[:page]).per(100)
  end

  def new
    @import = Influencer::Import.new
  end

  def import
    @import = Influencer::Import.new(influencer_import_params)
    if @import.save
      flash[:success] =
        "Imported #{@import.imported_count}
        #{'influencer'.pluralize(@import.imported_count)}.
        Updated #{@import.updated_count}
        #{'influencer'.pluralize(@import.updated_count)}."
      redirect_to new_influencer_path
    else
      flash.now[:danger] = "There were errors with your CSV file.
      Imported #{@import.imported_count}
      #{'influencer'.pluralize(@import.imported_count)}.
      Updated #{@import.updated_count}
      #{'influencer'.pluralize(@import.updated_count)}."
      render new_influencer_path
    end
  end

  def search
    @query = params[:query].presence.try(:strip) || '*'
    if @query == '*'
      @influencers = Influencer.all.page(params[:page]).per(100)
    else
      @influencers = Influencer.search_by_email_or_last_name(@query)
                               .order('created_at DESC').page(params[:page]).per(100)
    end
  end

  def edit
    @influencer = Influencer.find(params[:id])
  end

  def update
    @influencer = Influencer.find(params[:id])

    if @influencer.update(influencer_params)
      redirect_to edit_influencer_path(@influencer), notice: "Successfully updated #{@influencer.full_name}."
    else
      render :edit
    end
  end

  def delete
    count = 0
    influencers = Influencer.where(id: check_box_params[:influencers])
    influencers.each do |influencer|
      influencer.destroy && count += 1
    end

    flash[:success] = "#{count} #{'influencer'.pluralize(count)} deleted."
    redirect_to influencers_path 
  end

  # def download
  #   if check_box_params
  #     influencers = Influencer.where(id: check_box_params[:influencers])
  #     send_data(influencers.to_csv, type: 'csv', disposition: 'attachment', filename: "product-#{Time.now.strftime('%d/%m/%Y %H:%M:%S')}.csv")
  #   else
  #     flash['warning'] = 'You must select at least one influencer.'
  #     redirect_to influencers_path
  #   end
  # end

  private

  def influencer_import_params
    params.require(:influencer_import).permit(:file)
  end

  def influencer_params
    params.require(:influencer).permit(
      :first_name, :last_name, :email, :phone, :bra_size, :top_size,
      :bottom_size, :sports_jacket_size, :collection_id
    )
  end

  def check_box_params
    params.permit(influencers: [])
  end
end
