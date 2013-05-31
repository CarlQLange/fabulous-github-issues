Fabulous Github Issues for Hubot!
================================

Hubot is wonderful and I love him. And this makes him better at tracking your issues!
Who needs a PM when you have a robot?


-----------------------------------------------
`export HUBOT_GITHUB_TOKEN="yourtoken"`

`export HUBOT_GITHUB_REPO="user/reponame"`

You need to edit the script file and add your users to the USERS constant in the format
	`"Hipchat Name": "GithubUsername"`

Commands:
* `hubot new issue: <title>. <description>`
* `hubot assign (issue) #42 to <user>`
* `hubot tag (issue) #42 with <comma-seperated tag list>`
* `hubot close (issue) #42`
* `hubot show (me) my issues`
* `hubot show (me) <user>'s issues - NOT YET`
* `hubot show (me) issues`
* `hubot show (me) issues with <comma-seperated tag list> - NOT YET`
* `hubot add comment (to (issue)) #42: <comment>`
