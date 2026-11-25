@{
    RootModule        = 'HaseTools.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'ea27ae0d-059d-4eea-bb47-e17713ff0bf7'
    Description       = 'Shared commands of powershell-config: j bookmarks, config updates, nvim/Emacs launchers.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Update-Profile', 'Update-NvimConfig', 'Update-EmacsConfig'
        'nvim-dev', 'emacs-own', 'emacs-own-dev'
        'Get-Bookmarks', 'j', 'jp'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
