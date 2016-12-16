require 'spec_helper'

describe "subject linking" do

  before :all do
    @user = User.find_by(login: 'eleanor')
    collection_ids = Deed.where(user_id: @user.id).distinct.pluck(:collection_id)
    @collections = Collection.where(id: collection_ids)
    @collection = @collections.first
    @work = @collection.works.first
  end

  #it checks to make sure the subject is on the page
  it "looks at subjects in a collection" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Categories")
    categories = Category.where(collection_id: @collection.id)
    categories.each do |c|
      column = page.find('div.category-tree')
      expect(column).to have_content(c.title)
      column.click_link c.title
      c.articles.each do |a|
        expect(page).to have_content(a.title)
      end
    end
  end

  it "edits a subject's description" do 
    login_as(@user, :scope => :user)
    article = Article.first
    visit "/article/show?article_id=#{article.id}"
    expect(page).to have_content("Description")
    #this will fail if a description is already entered
    click_link("Edit the description in the settings tab")
    expect(page).to have_content("Description")
    expect(page).not_to have_content("Related Subjects")
    expect(page).not_to have_content("Delete Subject")
    page.fill_in 'article_source_text', with: "This is the text about my article."
    click_button('Save Changes')
    expect(page).to have_content("This is the text about my article.")
  end

  it "links a categorized subject" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.last
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
  #check to see if the links are regenerating on save
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "transcription").count
    expect(links).to eq 1
  #check the tooltip to explore a subject
    page.find('a', text: 'Texas').click
    expect(page).to have_content("Related Subjects")
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "transcription").count
    expect(links).to eq 1
  end

  it "enters a bad link - no closing braces" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.third
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Wrong number of closing braces")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

it "enters a bad link - no text" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.fourth
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[ ]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank tag")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

it "enters a bad link - no text in category then subject" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.fifth
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank subject")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places| ]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank text")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

  it "links subjects on a translation" do
    login_as(@user, :scope => :user)
    translate_work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    test_page = translate_work.pages.first
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Translate")
    expect(page).to have_content("Translation")
    page.fill_in 'page_source_translation', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "translation").count
    expect(links).to eq 1
  #check to see if the links are regenerating on save
    page.find('.tabs').click_link("Translate")
    expect(page).to have_content("Translation")
    page.fill_in 'page_source_translation', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "translation").count
    expect(links).to eq 1
  end

  it "tests autolinking in transcription" do
    login_as(@user, :scope => :user)
    link_work = @collection.works.second
    link_page = link_work.pages.first
    visit "/display/display_page?page_id=#{link_page.id}"
    page.find('.tabs').click_link("Transcribe")
    #make sure it doesn't autolink something that has no subject
    page.fill_in 'page_source_text', with: "Houston"
    click_button('Autolink')
    expect(page).not_to have_content("[[Places|Houston}}")
    #check that it links if there is a subject
    page.fill_in 'page_source_text', with: "Texas"
    click_button('Autolink')
    expect(page).to have_content("[[Places|Texas]]")
  end

  it "tests autolinking in translation" do
    login_as(@user, :scope => :user)
    translate_work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    test_page = translate_work.pages.last
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Translate")
    #make sure it doesn't autolink something that has no subject
    page.fill_in 'page_source_translation', with: "Houston"
    click_button('Autolink')
    expect(page).not_to have_content("[[Places|Houston}}")
    #check that it links if there is a subject
    page.fill_in 'page_source_translation', with: "Texas"
    click_button('Autolink')
    expect(page).to have_content("[[Places|Texas]]")
  end

end