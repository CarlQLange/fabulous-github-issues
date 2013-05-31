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
#	hubot show (me) <user>'s issues - NOT YET
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

#Your repo
REPO = process.env["HUBOT_GITHUB_REPO"]
#Hipchat User Name -> Github Username
USERS = {
	"Carl Lange": "CarlQLange"
}

issues = {}

issues.new = (msg, title, description, user) ->
	github.post "repos/#{REPO}/issues",
		{title: title, body: description},
		(res) ->
			msg.send "Created issue ##{res.number}."

issues.assign = (msg, number, user) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{assignee: user},
		(res) ->
			msg.send "Assigned issue ##{number} to #{user}."

issues.tag = (msg, number, tagList) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{labels: tagList},
		(res) ->
			msg.send "Replaced the tags on ##{number}."

issues.close = (msg, number) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{state: 'closed'},
		->
			msg.send "Closed ##{number}."

issues.get = (msg, user) ->
	github.get "repos/#{REPO}/issues", (issues) ->
		str = ""
		for issue in issues
			#TODO better formatting
			str += "##{issue.number}: Title: #{issue.title}, Description: #{issue.body}, Reporter: #{issue.user.login}, Tags: #{(label.name for label in issue.labels).toString()}\n"
		msg.send str

issues.comment = (msg, number, comment) ->
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

		issues.new(msg, title, description, user)

	robot.respond /assign(\s+issue)?\s+#(\d+)\sto\s(.*)/i, (msg) ->
		number = msg.match[2]
		user = msg.match[3]

		issues.assign(msg, number, user)

	robot.respond /tag\s+#(\d+)\swith\s(.*)/i, (msg) ->
		number = msg.match[1]
		tagList = msg.match[2].split(/,\s*/)

		issues.tag(msg, number, tagList)

	robot.respond /close\s+#(\d+)/i, (msg) ->
		number = msg.match[1]
		
		issues.close(msg, number)

	robot.respond /show\s+(me)?\s+(\S+)?\s*issues/i, (msg) ->
		if msg.match[2]
			if msg.match[2] is 'my'
				user = USERS[msg.message.user.name]
			else
				user = msg.match[2] #TODO better user matching

		issues.get(msg, user)

	robot.respond /(add(\s+a)?)?\s+comment\s+(to|on)?\s+#(\d*):\s*(.*)/i, (msg) -> #TODO better regex
		number = msg.match[4]
		comment = msg.match[5]

		comment += "\n\nComment by #{msg.message.user.name} (#{USERS[msg.message.user.name]}) via Fabulous-Github-Issues for Hubot."

		issues.comment(msg, number, comment)


