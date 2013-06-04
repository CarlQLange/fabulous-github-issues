# Description:
#	Interact with your issues on github in the most fabulous manner available to you
#
# Dependencies:
#   "githubot": "latest"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#   HUBOT_GITHUB_REPO
#
# Commands:
#	hubot new issue: <title>. <description> 
#	hubot assign (issue) #42 to <user>
#	hubot tag (issue) #42 with <comma-seperated tag list>
#	hubot close (issue) #42
#	hubot show (me) my issues
#	hubot show (me) <user>'s issues
#	hubot show (me) issues
#	hubot show (me) issues with <comma-seperated tag list> - NOT YET
#	hubot add comment (to (issue)) #42: <comment>
#
# Notes:
#	export HUBOT_GITHUB_TOKEN="yourtoken"
#	export HUBOT_GITHUB_REPO="user/reponame"
#	You need to edit the script file and add your users to the USERS constant in the format
#		Hipchat Name: GithubUsername
#
# Author:
#	Carl Lange (@csl_)

http = require 'https'
github = require 'githubot'

REPO = process.env["HUBOT_GITHUB_REPO"]
#Hipchat User Name -> Github Username
USERS = {
	"Carl Lange": "CarlQLange"
}

Issues = {}

Issues.new = (msg, title, description, user) ->
	github.post "repos/#{REPO}/issues",
		{title: title, body: description},
		(res) ->
			msg.send "Created issue ##{res.number}."

Issues.assign = (msg, number, user) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{assignee: user},
		(res) ->
			msg.send "Assigned issue ##{number} to #{user}."

Issues.tag = (msg, number, tagList) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{labels: tagList},
		(res) ->
			msg.send "Replaced the tags on ##{number}."

Issues.close = (msg, number) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{state: 'closed'},
		->
			msg.send "Closed ##{number}."

Issues.get = (msg, user) ->
	github.get "repos/#{REPO}/issues", (issues) ->
		if user
			issues = issues.filter (el) ->
				el.assignee? and el.assignee.login is user

		msg.send Issues.formatIssues(issues)

Issues.formatIssues = (issues) ->
	str = ""
	for issue in issues
		str += Issues.formatIssue issue
	str

Issues.formatIssue = (issue) ->
	"##{issue.number}: Title: #{issue.title}, Description: #{issue.body}, Reporter: #{issue.user.login}, Tags: #{(label.name for label in issue.labels).toString()}\n"
 

Issues.comment = (msg, number, comment) ->
	github.post "repos/#{REPO}/issues/#{number}/comments",
		{body: comment},
		->
			msg.send "Commented on ##{number}."


module.exports = (robot) ->
	github = github robot

	robot.respond /(new)?\s*issue\s*(me)?(:)?\s*([^\.]*[^\s]*)(.*)/i, (msg) ->
		title = msg.match[4]
		description = msg.match[5]
		user = msg.message.user.name #TODO user matching

		Issues.new(msg, title, description, user)

	robot.respond /assign(\s+issue)?\s+#(\d+)\sto\s(.*)/i, (msg) ->
		number = msg.match[2]
		user = msg.match[3]

		Issues.assign(msg, number, user)

	robot.respond /tag\s+#(\d+)\swith\s(.*)/i, (msg) ->
		number = msg.match[1]
		tagList = msg.match[2].split(/,\s*/)

		Issues.tag(msg, number, tagList)

	robot.respond /close\s+#(\d+)/i, (msg) ->
		number = msg.match[1]
		
		Issues.close(msg, number)

	robot.respond /show(\s+me)?(\s?\w+)?('s)?\s*issues/i, (msg) ->
		if msg.match[2]
			if msg.match[2].trim() is 'my'
				user = USERS[msg.message.user.name]
			else
				for name of USERS
					if name.match(/(\w*)\s/)[1].trim().toLowerCase() is msg.match[2].trim().toLowerCase()
						user = USERS[name]

		Issues.get(msg, user)

	robot.respond /(add(\s+a)?)?\s+comment\s+(to|on)?\s+#(\d*):\s*(.*)/i, (msg) -> #TODO better regex
		number = msg.match[4]
		comment = msg.match[5]

		comment += "\n\nComment by #{msg.message.user.name} (#{USERS[msg.message.user.name]}) via Fabulous-Github-Issues for Hubot."

		Issues.comment(msg, number, comment)

