module RedmineDrafts

  class Hooks < Redmine::Hook::ViewListener
    # Add our own elements to issue show view (in show and form sections)
    #
    # NB: This works too, maybe for future use if we have many things to 
    # do before rendering :
    #
    #   def view_issues_form_details_bottom(context)
    #     template = context[:controller].instance_variable_get("@template")
    #     template.render :partial => "drafts/issue_form", :locals => {:context => context}
    #   end
    #

    render_on :view_issues_form_details_bottom, :partial => "drafts/issue_form"
    render_on :view_issues_show_details_bottom, :partial => "drafts/issue_show"
    render_on :view_layouts_base_body_bottom, :partial => "drafts/wiki_form"
    # render_on :view_wiki_edit, :partial => "drafts/wiki_form"

    # Add our css/js on each page
    def view_layouts_base_html_head(context)
      javascript_include_tag('jquery.observe-form.js', :plugin => 'redmine_drafts')
    end

    def is_wiki?(context)
      User.current.logged? && context[:controller].is_a?(WikiController)
    end

  end
end
