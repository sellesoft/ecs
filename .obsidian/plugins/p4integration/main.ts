import 
{ 
	Editor, 
	MarkdownView, 
	Notice, 
	Plugin, 
	FileSystemAdapter,
} from 'obsidian';

// For running p4.
import { promisify } from 'util';
import { exec } from 'child_process';
const pexec = promisify(exec)

interface P4IntegrationSettings 
{
}

const DEFAULT_SETTINGS: P4IntegrationSettings = 
{
}

const debounce = (callback: any, wait: number) =>
{
	let timeout_id: number | undefined;
	return (...args: any[]) =>
	{
		window.clearTimeout(timeout_id);
		timeout_id = window.setTimeout(() =>
		{
			callback(...args);
		}, wait)
	}
}

export default class P4Integration extends Plugin 
{
	settings: P4IntegrationSettings;
	fs: FileSystemAdapter;
	file_map: Map<string, (...args:any[]) => void> = new Map();

	async editOrAddFile(path: string, name: string)
	{
		let result = await this.execP4Command("edit", path);
	
		// Check if we just opened for edit.
		if (result.stdout.length != 0)
		{
			// And notify if so.
			if (result.stdout.match(/(?<!currently )opened for edit/))
				new Notice(`checked out ${name}`)
		}
		
		if (result.stderr.length != 0)
		{
			// Otherwise mark for add if file is unversioned.
			if (result.stderr.match(/file\(s\) not on client/))
			{
				let result = await this.execP4Command("add", path)
				if (result.stdout.match(/(?<!already )opened for add/))
				{
					new Notice(`marked ${name} for add`)
				}
			}
		}
	}

  // Invoked when the user (or something programatically) makes a change 
  // to the file currently open in the Editor.
  onEditorChange(editor: Editor, info: MarkdownView)
  {
		if (info.file == null)
			return;

		const short_path = info.file.path;
		const full_path = `${this.fs.getBasePath()}/${short_path}`;

		// Try to get a previously created debounced callback for calling into 
		// p4. We debounce this to avoid sending commands to p4 on every keystroke.
		let cb = this.file_map.get(full_path)
		if (cb == undefined)
		{
			// Create and cache the callback if we don't already have one for this 
			// file.
			cb = debounce(() =>
			{
				this.editOrAddFile(full_path, short_path)
			}, 1000)

			this.file_map.set(full_path, cb)
		}

		cb();
  }

	async onload() 
	{
		await this.loadSettings();
		
		// Obsidian prefers you use their Vault api to deal with files in the 
		// vault as it can be run on mobile and such. However, this does not 
		// provide access to absolute paths that we need to give to p4.
		// Since p4 is not on mobile, we just assume desktop and get the underlying
		// FileSystemAdapter here.
		this.fs = this.app.vault.adapter as FileSystemAdapter;

		// TODO(sushi) maybe sometime add a status for the state of the file 
		//             under p4.
		//
		// This adds a status bar item to the bottom of the app. 
		// const statusBarItemEl = this.addStatusBarItem();
		// statusBarItemEl.setText('Status Bar Text');
		
		this.registerEvent(this.app.workspace.on('editor-change', 
				this.onEditorChange, 
				this));

		this.addCommand(
		{
			id: 'p4-checkout',
			name: 'P4 Checkout',
			editorCallback: (_, ctx: MarkdownView) => 
			{ 
				if (ctx.file != null)
					this.execP4Command("edit", ctx.file.path); 
			}
		});

		this.addCommand(
		{
			id: 'p4-add',
			name: 'P4 Add',
			editorCallback: (_, ctx: MarkdownView) => 
			{ 
				if (ctx.file != null)
					this.execP4Command("add", ctx.file.path); 
			}
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

	// Executes a p4 command on the given path (which should be absolute).
	async execP4Command(cmd: string, path: string)
	{
		const cwd = this.fs.getBasePath();
		const env = process.env;

		const full_cmd = `p4 ${cmd} ${path}`;

		const result = await pexec(full_cmd,
		{
			cwd: cwd,
			env: env,
		});

		return result
	}
}

