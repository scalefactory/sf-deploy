# SFDeploy

This is an open source project published by The Scale Factory.

We currently consider this project to be archived.

:warning: We’re no longer using or working on this project. It remains available for posterity or reference, but we’re no longer accepting issues or pull requests.

SFDeploy is a tool for pull-based software deployment.

## What problem does it solve?

Tools like capistrano, fabric et al are designed primarily for push-based deployment: from some central location, you configure a list of target hosts and use the tool to push configuration to them.

In a more dynamic environment, such as might be found in an auto-scaled cloud infrastructure, we don't always know where our resources are located, or how many servers we're operating with.  This tool attempts to offer a solution to this problem by combining a simple git-based deploy process with centralised orchestration managed by [MCollective](http://puppetlabs.com/mcollective). 


## How does it work?

SFDeploy consists of a command line tool for local operation, and an MCollective agent for remote orchestration.

SFDeploy maintains a bare mirror of your git repository on each target server.  Whenever you make changes to your central git repo, you use the MCollective agent to issue a command that will update the mirrors across your whole server estate.

When you're ready to deploy your application, you again use the MCollective agent and request deployment of a new version of the app - specified either by branch (the latest revision from that branch will be deployed) or by tag.


## License

Made available under the MIT license.  See the LICENSE file for details.
