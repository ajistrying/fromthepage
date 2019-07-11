class PageVersion < ActiveRecord::Base
  belongs_to :page
  belongs_to :user

  def display
    self.created_on.strftime("%b %d, %Y") + " - " + self.user.display_name
  end

  def prev
    page.page_versions.where("id < ?", id).first
  end

  def next
  	page.page_versions.where("id > ?", id).last
  end

  def current_version?
  	self.id == page.page_versions.pluck(:id).max
  end

  def expunge
  	# if we are we the current version
  	if self.current_version?
	  	#   copy the previous version's contents into the page and save without callbacks
	  	previous_version = self.prev
    	page.update_columns(
    		:title => previous_version.title,
    		:source_text => previous_version.transcription,
    		:xml_text => previous_version.xml_transcription,
    		:source_translation => previous_version.source_translation,
    		:xml_translation => previous_version.xml_translation
		)
  	else
  	#   renumber subsequent versions
  		this_version = self
  		while next_version = this_version.next do
  			next_version.page_version -= 1
  			next_version.save!
  			this_version = next_version
  		end
  	end
  	self.destroy!
  end

end