class DraftsController < ApplicationController
  unloadable
  
  before_filter :require_login

  def autosave
    set_kind_from_params
    case @kind
    when 'issue'
      #Redmine 2.1.x had params[:notes] while Redmine 2.2.x moved it to
      #params[:issue][:notes] when introducing private notes. We want to
      #support both formats so we need to save and restore at both places.
      params[:issue] ||= {}
      params[:notes] = params[:issue][:notes] if params[:notes].blank?
      params[:issue][:notes] = params[:notes] if params[:issue][:notes].blank?
        
    
      #decide whether the record should be saved
      has_to_be_saved = !params[:notes].blank?
      has_to_be_saved ||= (params[:issue_id].to_i == 0 && !params[:issue][:subject].blank?)
      #if so, save it!
      if request.xhr? && has_to_be_saved
        @draft = Draft.find_or_create_for_issue(:user_id => User.current.id,
                                                  :element_id => params[:issue_id].to_i)
        new_content = params.reject{|k,v| !%w(issue notes).include?(k)}
        unless @draft.content == new_content
          @draft.content = new_content
          if @draft.save
            render :partial => "saved", :layout => false
          else
            render :text => "Error saving draft"
          end
        end
      end
    when 'wiki'
      has_to_be_saved = !params[:content][:text].blank?
      if request.xhr? && has_to_be_saved
      @draft = Draft.find_or_create_for_wiki(:user_id => User.current.id,
                                              :element_id => params[:wiki_id].to_i)
      new_content = params.reject{|k,v| !%w(content).include?(k)}
        unless @draft.content == new_content
          @draft.content = new_content
          if @draft.save
            render :partial => "saved", :layout => false
          else
            render :text => "Error saving draft"
          end         
        end
      end
    end
    render :nothing => true unless performed?
  end

  def set_kind_from_params
    if !params[:issue].nil? || !params[:issue_id].nil?
      @kind = 'issue'
    elsif !params[:wiki_id].nil?
      @kind = 'wiki'
    elsif !params[:news].nil?
      @kind = 'news'
    else
      @kind = nil
    end
  end

  def restore
    @draft = Draft.find(params[:id])
    kind = @draft[:element_type].downcase!
    case kind
    when 'issue'
      self.restore_issue
    when 'wiki'
      self.restore_wiki
    end
  end

  def restore_issue
    if @draft.element_id == 0
      redirect_to({:controller => "issues", :action => "new", :project_id => params[:project_id].to_i, :draft_id => @draft})
    else
      redirect_to({:controller => "issues", :action => "edit", :id => @draft.element_id, :draft_id => @draft})
    end
  end

  def restore_wiki
    redirect_to({:controller => 'wiki', :action => 'edit', :project_id => params[:project_id].to_i, :draft_id => @draft})
  end

   
  def destroy
    @draft = Draft.find(params[:id])
    @draft.destroy
    respond_to do |format|
       format.js
     end
  end
end
