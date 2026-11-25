# This machine's additions to the profile. Not tracked in git.
# To use: copy local-template.ps1 to local.ps1 next to it, then edit local.ps1.
#
# The profile dot-sources local.ps1 last, so anything here runs in the session's
# scope and wins over the shared setup: set variables, add functions and aliases,
# or redefine a shared command with the same name.

# Config locations used by HaseTools, if they differ on this machine
# $EmacsConfigDir    = 'D:\emacs-config'
# $EmacsConfigDevDir = 'D:\proj\emacs-config'

# Machine-only aliases and functions
# Set-Alias py python
# function work { Set-Location 'D:\work' }

# Override a shared command
# function emacs-own { runemacs @args }
