import 
{ 
	App, 
	Editor, 
	MarkdownView, 
	Modal, 
	Notice, 
	Plugin, 
	PluginSettingTab, 
	Setting, 
    FileSystemAdapter,
} from 'obsidian';

const { exec } = require('child_process')

// Remember to rename these classes and interfaces!

interface MyPluginSettings 
{
	mySetting: string;
}

const DEFAULT_SETTINGS: MyPluginSettings = 
{
	mySetting: 'default'
}

export default class MyPlugin extends Plugin 
{
	settings: MyPluginSettings;

	async onload() 
	{
		await this.loadSettings();

		// TODO(sushi) it would be nice to automatically checkout files 
		//             when Obsidian tries to write it to disk, but atm their
		//             api only provides on('modify'), which is called once 
		//             the file is actually written. So we never get notified 
		//             of this since it errors out due to them being read-only.
		//
		//             Should make a forum post about this at some point.

		// TODO(sushi) maybe sometime add a status for the state of the file 
		//             under p4.
		//
		// This adds a status bar item to the bottom of the app. 
		// const statusBarItemEl = this.addStatusBarItem();
		// statusBarItemEl.setText('Status Bar Text');

		this.addCommand(
		{
			id: 'p4-checkout',
			name: 'P4 Checkout',
			callback: () => { this.execP4Command("edit"); }
		});

		this.addCommand(
		{
			id: 'p4-add',
			name: 'P4 Add',
			callback: () => { this.execP4Command("add"); }
		});
	}

	onunload() { }

	async loadSettings() 
	{
		this.settings = 
			Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
	}

	async saveSettings() 
	{
		await this.saveData(this.settings);
	}

	// Executes a p4 command on the current file.
	async execP4Command(cmd: string)
	{
		const adapter = this.app.vault.adapter;
		if (!(adapter instanceof FileSystemAdapter))
			return;

		const cwd = adapter.getBasePath();
		const env = process.env;

		const file = this.app.workspace.activeEditor?.file;
		if (file == null)
		{
			new Notice("No file to checkout");
			return;
		}

		exec(`p4 ${cmd} ${file.path}`, 
		{
			cwd: cwd,
			env: env,
		}, 
		(err, stdout, stderr) =>
		{
			if (err)
			{
				new Notice(`p4 ${cmd} ${file} failed:\n${err}`)
				return;
			}

			new Notice(`p4 ${cmd} ${file}\n${stdout}`);
		});
	}
}

