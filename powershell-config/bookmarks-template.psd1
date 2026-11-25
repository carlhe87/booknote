# This machine's bookmarks for the `j` function. Not tracked in git.
# Created from bookmarks-template.psd1 on first use; edit freely (`j marks`).
#
# Usage:
#   j           list all bookmarks
#   j <name>    folder: cd there | file: cd to its folder and open it
#               (md, org, txt and other listed text types in nvim; the rest in the default app)
#   popd        go back to where you were
#   jp <name>   output the full path, to use in other commands: Copy-Item (jp <name>) D:\
#
# Format: name = 'path'. Names are tab-completed.
# Use %VAR% for environment variables, e.g. %USERPROFILE%, %LOCALAPPDATA%.
@{
    # Files: `j <name>` changes to the file's folder and opens the file
    nvim  = '%LOCALAPPDATA%\nvim\init.lua'
    marks = '%USERPROFILE%\Documents\WindowsPowerShell\bookmarks.psd1'   # this file
    # todo = '%USERPROFILE%\Documents\todo.org'

    # Folders: `j <name>` changes to the folder
    # home      = '%USERPROFILE%'
    # docs      = '%USERPROFILE%\Documents'
    # downloads = '%USERPROFILE%\Downloads'
    # proj      = '%USERPROFILE%\proj'
}
