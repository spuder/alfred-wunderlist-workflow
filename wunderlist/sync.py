def sync():
	from wunderlist.models import base, root, list, task, user

	base.BaseModel._meta.database.create_tables([
		root.Root,
		list.List,
		task.Task,
		user.User
	], safe=True)

	root.Root.sync()

def backgroundSync():
	from workflow.background import run_in_background, is_running
	from wunderlist.util import workflow

	# Only runs if another sync is not already in progress
	run_in_background('sync', [
		'/usr/bin/env',
		'python',
		workflow().workflowfile('alfred-wunderlist-workflow.py'),
		'sync',
		'--commit'
	])