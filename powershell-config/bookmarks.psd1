# Shared bookmarks for the `j` function (see Microsoft.PowerShell_profile.ps1).
# Same on every machine and tracked in git: change them in the dev repo
# (~/proj/powershell-config), not in the profile folder.
# For this machine's own bookmarks, use bookmarks-local.psd1 (`j marks`).
#
# Usage:
#   j           list all bookmarks
#   j <name>    folder: cd there | file: cd to its folder and open it in nvim
#   j marks     edit this machine's bookmarks-local.psd1
#   popd        go back to where you were
#
# Format: name = 'path'. Names are tab-completed.
# Use %VAR% for environment variables so paths work on every machine.
@{
    # Folders: `j <name>` changes to the folder
    home      = '%USERPROFILE%'
    docs      = '%USERPROFILE%\Documents'
    downloads = '%USERPROFILE%\Downloads'

    # Files: `j <name>` changes to the file's folder and opens the file in nvim
    nvim      = '%LOCALAPPDATA%\nvim\init.lua'
    marks     = '%USERPROFILE%\Documents\WindowsPowerShell\bookmarks-local.psd1'
}
