metadata  :name         => "sfdeploy",
          :description  => "Orchestrated pull-based software deployment",
          :author       => "Jon Topper <jon@scalefactory.com>",
          :license      => "MIT License",
          :version      => "1.0",
          :url          => "http://scalefactory.com/",
          :timeout      => 10

action "git_clone", :description => "Create or update the bare git clone for the application" do
    display :always
end

action "show_tags", :description => "Display available tags for the application" do
    display :always
    output :tags,
        :description => "Available tags",
        :display_as  => "Available tags"
end

action "show_branches", :description => "Display available branches for the application" do
    display :always
    output :branches,
        :description => "Available branches",
        :display_as  => "Available branches"
end

action "deploy_tag", :description => "Deploy a tagged version of the application" do
end

action "deploy_branch", :description => "Deploy the app from the tip of the named branch" do
end

action "run_post_deploy", :description => "Run the post-deploy scripts for the current app" do
end

action "current_metadata", :description => "Show metadata for the current released app" do
    display :always
    output  :metadata,
        :description => "Current release metadata",
        :display_as  => "Metadata"
end
