PersianKit @VERSION@ for Notepad++ - RTL editing, Vazirmatn font, JSON/JSONL helpers.

Install (the same layout Plugins Admin uses):
  close Notepad++, create <Notepad++>\plugins\PersianKit\ and put this
  PersianKit.dll in it, then restart Notepad++.
  Portable build? <portable folder>\plugins\PersianKit\PersianKit.dll
  If Windows shows an "Unblock" box in the DLL's Properties, click it first.

Commands: Persian mode | Toggle RTL/LTR (Alt+Shift+R) | Apply Vazirmatn |
          Auto for .md/.txt | JSON: format (JSON and JSONL) | JSON: fold all

RTL needs: DirectWrite off (Settings > Preferences > MISC, restart) and a
           UTF-8 document; the plugin warns when either is missing.

Large JSON/JSONL files:
  * above JsonlMaxSizeMB (default 16 MB) the plugin keeps the plain-text lexer
    and turns word wrap off for that buffer, so the file opens instantly
  * JSON: format refuses documents above JsonMaxFormatMB (default 32 MB)
  Both keys are in plugins\config\NppPersianKit.ini

Source:   https://github.com/ahmadkhanloo/npp-persian-kit  (GPL-3.0)
Font:     Vazirmatn by Saber Rastikerdar (OFL-1.1) - shipped separately in
          NotepadPlusPlus-Persian-Kit.zip, not in this plugin package.
