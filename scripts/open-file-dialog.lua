-- To the extent possible under law, the author(s) have dedicated all copyright
-- and related and neighboring rights to this software to the public domain
-- worldwide. This software is distributed without any warranty. See
-- <https://creativecommons.org/publicdomain/zero/1.0/> for a copy of the CC0
-- Public Domain Dedication, which applies to this software.

utils = require 'mp.utils'

function open_file_dialog()
	local was_ontop = mp.get_property_native("ontop")
	if was_ontop then mp.set_property_native("ontop", false) end
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
			Trap {
				Write-Error -ErrorRecord $_
				Exit 1
			}
			Add-Type -AssemblyName PresentationFramework

			$u8 = [System.Text.Encoding]::UTF8
			$out = [Console]::OpenStandardOutput()

			$ofd = New-Object -TypeName Microsoft.Win32.OpenFileDialog
			$ofd.Multiselect = $true

			If ($ofd.ShowDialog() -eq $true) {
				ForEach ($filename in $ofd.FileNames) {
					$u8filename = $u8.GetBytes("$filename`n")
					$out.Write($u8filename, 0, $u8filename.Length)
				}
			}
		}]]},
		cancellable = false,
	})
	if was_ontop then mp.set_property_native("ontop", true) end
	if (res.status ~= 0) then
		return nil
	end

	return res.stdout
end

function open_files()
	local files = open_file_dialog()

	if files ~= nil then
		local first_file = true
		for filename in string.gmatch(files, '[^\n]+') do
			mp.commandv('loadfile', filename, first_file and 'replace' or 'append')
			first_file = false
		end
	end
end

function append_files()
	local files = open_file_dialog()

	if files ~= nil then
		local first_file = true
		for filename in string.gmatch(files, '[^\n]+') do
			mp.commandv('loadfile', filename, 'append')
			first_file = false
		end
	end
end

function add_videos()
	local files = open_file_dialog()

	if files ~= nil then
		local first_file = true
		for filename in string.gmatch(files, '[^\n]+') do
			mp.commandv('video-add', filename)
			first_file = false
		end
	end
end

function add_audios()
	local files = open_file_dialog()

	if files ~= nil then
		local first_file = true
		for filename in string.gmatch(files, '[^\n]+') do
			mp.commandv('audio-add', filename)
			first_file = false
		end
	end
end

function add_subs()
	local files = open_file_dialog()

	if files ~= nil then
		local first_file = true
		for filename in string.gmatch(files, '[^\n]+') do
			mp.commandv('sub-add', filename)
			first_file = false
		end
	end
end

mp.register_script_message('open-files', open_files)
mp.register_script_message('append-files', append_files)
mp.register_script_message('add-videos', add_videos)
mp.register_script_message('add-audios', add_audios)
mp.register_script_message('add-subs', add_subs)
