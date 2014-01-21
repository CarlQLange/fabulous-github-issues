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
#	hubot show (me) issues with <comma-seperated tag list>
#	hubot show (me) issue #42
#	hubot show (me) unapproved issues
#	hubot show (me) milestones
#	hubot show (me) milestone 4
#	hubot add #42 to milestone 3
#	hubot remove #42 from milestone 3
#	hubot add comment (to (issue)) #42: <comment>
#
# Notes:
#	export HUBOT_GITHUB_TOKEN="yourtoken"
#	export HUBOT_GITHUB_REPO="user/reponame"
#	You need to edit the script file and add your users to the USERS constant in the format
#		Chat Name: GithubUsername
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


Array::isSubsetOf = (other) -> #probably not accurate terminology but fuck you mathematics
	@.filter((el) -> el in other).length is @.length

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
	github.get "repos/#{REPO}/issues/#{number}", (issue) ->
		tagList = tagList.concat(label.name for label in issue.labels)

		github.post "repos/#{REPO}/issues/#{number}",
			{labels: tagList},
			(res) ->
				msg.send "Added tags to ##{number}."

Issues.close = (msg, number) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{state: 'closed'},
		->
			msg.send "Closed ##{number}."

Issues.reopen = (msg, number) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{state: 'open'},
		->
			msg.send "Reopened ##{number}."

Issues.get = (msg, user, number, tagList) ->
	if number
		github.get "repos/#{REPO}/issues/#{number}", (issue) ->
			msg.send Issues.formatIssueLong(issue)
	else
		github.get "repos/#{REPO}/issues", (issues) ->
			if user
				issues = issues.filter (el) ->
					el.assignee? and el.assignee.login is user

			if tagList
				issues = issues.filter (el) ->
					(tag.name for tag in el.labels).isSubsetOf(tagList)
					

			msg.send Issues.formatIssues(issues)

Issues.addToMilestone = (msg, issue, milestone) ->
	github.post "repos/#{REPO}/issues/#{issue}",
		{milestone: milestone},
		->
			msg.send "Added ##{issue} to milestone #{milestone}"

Issues.removeFromMilestone = (msg, issue) ->
	github.post "repos/#{REPO}/issues/#{number}",
		{milestone: null}, #guessing here because I don't have access to API docs
		->
			msg.send "Removed ##{issue} from its milestone"

Issues.getMilestone = (msg, number) ->
	if number
		github.get "repos/#{REPO}/milestones/#{number}", (milestone) ->
			msg.send Issues.formatMilestoneLong(milestone)
	else
		github.get "repos/#{REPO}/milestones", (milestones) ->
			msg.send Issues.formatMilestones(milestones)

Issues.getPulls = (msg) ->
	github.get "repos/#{REPO}/pulls", (pulls) ->
		if (pulls?)
			msg.send Issues.formatPulls(pulls)
		else
			msg.send "Couldn't find any open pull requests."

Issues.getApprovedPulls = (msg) ->
	github.get "repos/#{REPO}/pulls", (pulls) ->
		if (pulls?)
			pulls.forEach (el, i) ->
				github.get "repos/#{REPO}/statuses/#{el.head.sha}", (statuses) ->
					if (statuses.length isnt 0 and statuses[0].state is "success")
						msg.send Issues.formatPull el
		else
			msg.send "Couldn't find any open pull requests."

Issues.getUnapprovedPulls = (msg) ->
	github.get "repos/#{REPO}/pulls", (pulls) ->
		if (pulls?)
			pulls.forEach (el, i) ->
				github.get "repos/#{REPO}/statuses/#{el.head.sha}", (statuses) ->
					if (statuses.length is 0 or statuses[0].state isnt "success")
						msg.send Issues.formatPull el
		else
			msg.send "Couldn't find any open pull requests."

Issues.mergePull = (msg, number) ->
	github.request "PUT", "/repos/#{REPO}/pulls/#{number}/merge", (res) ->
		msg.send res.message

Issues.formatPulls = (pulls) ->
	str = ""
	for pull in pulls
		str += Issues.formatPull pull
	str

Issues.formatPull = (pull) ->
	"##{pull.number}: #{pull.title} by #{pull.user.login}\n"

Issues.formatIssues = (issues) ->
	str = ""
	for issue in issues
		str += Issues.formatIssueShort issue
	str

Issues.formatIssueLong = (issue) ->
	"##{issue.number}: #{issue.title}\n\nTags: #{(label.name for label in issue.labels)}\n\n#{issue.body}"

Issues.formatIssueShort = (issue) ->
	"##{issue.number}: #{issue.title}, Description: #{issue.body}\n"

Issues.formatMilestones = (milestones) ->
	str = ""
	for milestone in milestones
		str += Issues.formatMilestoneShort milestone
	str

Issues.formatMilestoneShort = (ms) ->
	percentage = ms.closed_issues / (ms.open_issues + ms.closed_issues) * 100

	"##{ms.number}: #{ms.title} -- #{percentage}%\n"

Issues.formatMilestoneLong = (ms) ->
	#this should show open issues left
	"#{Issues.formatMilestoneShort(ms)}\t#{ms.description}"

Issues.comment = (msg, number, comment) ->
	github.post "repos/#{REPO}/issues/#{number}/comments",
		{body: comment},
		->
			#msg.send "Commented on ##{number}."

module.exports = (robot) ->
	github = github robot

	robot.respond /(new)?\s*issue\s*(me)?(:)?\s*([^\.]*[^\s]*)(.*)/i, (msg) ->
		title = msg.match[4]
		description = msg.match[5]
		user = msg.message.user.name

		description += "\n\nOpened by #{msg.message.user.name} (@#{USERS[msg.message.user.name]}) via Fabulous-Github-Issues for Hubot."

		Issues.new(msg, title, description, user)

	robot.respond /assign(\s+issue)?\s+#(\d+)\sto\s(.*)/i, (msg) ->
		number = msg.match[2]
		user = getGithubName msg.match[3], msg

		Issues.assign(msg, number, user)

	robot.respond /tag\s+#(\d+)\swith\s(.*)/i, (msg) ->
		number = msg.match[1]
		tagList = msg.match[2].split(/,\s*/)

		Issues.tag(msg, number, tagList)

	robot.respond /add\s+#(\d+)\s+to\s+(milestone\s+)?(\d+)/, (msg) ->
		issue = msg.match[1]
		milestone = msg.match[3]

		Issues.addToMilestone(msg, issue, milestone)

	robot.respond /remove\s+#(\d+)\s+from\s+(milestone\s+)?(\d+)/, (msg) ->
		issue = msg.match[1]
		milestone = msg.match[3] #we don't actually need this

		Issues.removeFromMilestone(msg, issue)

	robot.respond /close\s+#(\d+)/i, (msg) ->
		number = msg.match[1]
		
		Issues.close(msg, number)

	robot.respond /reopen\s+#(\d+)/i, (msg) ->
		number = msg.match[1]

		Issues.reopen(msg, number)

	robot.respond /show(\s+me)?(\s?\w+)?('s)?\s*issues/i, (msg) ->
		if msg.match[2]
			user = getGithubName msg.match[2], msg

		Issues.get(msg, user)

	robot.respond /show(\s+me)?(\s+issue)?\s+#(\d*)/i, (msg) ->
		number = msg.match[3]

		Issues.get(msg, null, number)

	robot.respond /show(\s+me)?\s+issues\s+with\s+(.*)/i, (msg) ->
		tagList = msg.match[2].split(/,\s*/)

		Issues.get(msg, null, null, tagList)

	robot.respond /show(\s+me)?\s+approved\s+pulls/i, (msg) ->
		Issues.getApprovedPulls(msg)

	robot.respond /show(\s+me)?\s+unapproved\s+pulls/i, (msg) ->
		Issues.getUnapprovedPulls(msg)

	robot.respond /show(\s+me)?\s+milestones/i, (msg) ->
		Issues.getMilestone(msg)
	
	robot.respond /show(\s+me)?\s+milestone\s+#(\d+)/i, (msg) ->
		number = msg.match[2]

		Issues.getMilestone(msg, number)

	robot.respond /show(\s+me)\s+pulls/i, (msg) ->
		Issues.getPulls(msg)

	robot.respond /list\s+pulls/i, (msg) ->
		Issues.getPulls(msg)

	robot.respond /merge\s+#(\d*)/, (msg) ->
		number = msg.match[1]

		Issues.mergePull(msg, number)

	robot.respond /(add(\s+a)?)?\s+comment\s+(to|on)?\s+#(\d*):\s*(.*)/i, (msg) -> #TODO better regex
		number = msg.match[4]
		comment = msg.match[5]

		comment += "\n\nComment by #{msg.message.user.name} (@#{USERS[msg.message.user.name]}) via Fabulous-Github-Issues for Hubot."

		Issues.comment(msg, number, comment)

	robot.respond /c(\s+)?#(\d+)\s+(.*)/, (msg) ->
		number =  msg.match[2]
		comment = msg.match[3]

		comment += "\n\nComment by #{msg.message.user.name} (@#{USERS[msg.message.user.name]}) via Fabulous-Github-Issues for Hubot."

		Issues.comment(msg, number, comment)


getGithubName = (shortName, msg) ->
	shortName = shortName.trim()
	if shortName is 'me' or shortName is 'my'
		name = msg.message.user.name
	else
		for user of USERS
			if user.match(/(\w*)\s/)[1].trim().toLowerCase() is shortName.trim().toLowerCase()
				name = user
	USERS[name]

