/*
 *  npp_api.h  -  minimal Notepad++ plugin ABI used by PersianKit.
 *
 *  The message numbers below come from Notepad++'s public plugin interface
 *  (PowerEditor/src/MISC/PluginsManager/Notepad_plus_msgs.h) and Scintilla's
 *  Scintilla.h.  They are re-declared here so the plugin can be built
 *  stand-alone, without vendoring Notepad++ sources.
 *
 *  This file is part of PersianKit, licensed under the GNU GPL v3 (see LICENSE).
 */
#pragma once

#include <windows.h>

/* ---- Notepad++ plugin messages ------------------------------------------- */
#define NPPMSG                       (WM_USER + 1000)
#define NPPN_FIRST                   1000
#define NPPN_READY                   (NPPN_FIRST + 1)
#define NPPN_TBMODIFICATION          (NPPN_FIRST + 2)
#define NPPN_BUFFERACTIVATED         (NPPN_FIRST + 10)

#define NPPM_GETCURRENTSCINTILLA     (NPPMSG + 4)   /* out: int* view (0=main,1=second) */
#define NPPM_GETCURRENTLANGTYPE      (NPPMSG + 5)   /* out: int* LangType                 */
#define NPPM_SETMENUITEMCHECK        (NPPMSG + 40)  /* wParam: cmdID, lParam: 0/1         */
#define NPPM_GETPLUGINSCONFIGDIR     (NPPMSG + 46)  /* out: wchar_t* buffer (MAX_PATH)    */

#define RUNCOMMAND_USER              (WM_USER + 3000)
#define EXT_PART                     5
#define NPPM_GETEXTPART              (RUNCOMMAND_USER + EXT_PART)

/* ---- Scintilla ----------------------------------------------------------- */
#define SC_CP_UTF8                   65001
#define STYLE_MAX                    255

#define SCI_SETCODEPAGE              2037
#define SCI_GETCODEPAGE              2137
#define SCI_STYLESETBOLD             2053
#define SCI_STYLESETSIZE             2055
#define SCI_STYLESETFONT             2056
#define SCI_GETBIDIRECTIONAL         2708
#define SCI_SETBIDIRECTIONAL         2709

/* text / undo / folding */
#define SCI_GETLENGTH                2006
#define SCI_GETTABWIDTH              2121
#define SCI_GETUSETABS               2125
#define SCI_BEGINUNDOACTION          2078
#define SCI_ENDUNDOACTION            2079
#define SCI_SETSEL                   2160
#define SCI_REPLACESEL               2170
#define SCI_GETTEXT                  2182
#define SCI_FOLDALL                  2662
#define SC_FOLDACTION_CONTRACT       0

#define SC_BIDIRECTIONAL_DISABLED    0
#define SC_BIDIRECTIONAL_R2L         2

/* ---- plugin ABI ---------------------------------------------------------- */
struct NppData
{
    void* _nppHandle;
    void* _scintillaMainHandle;
    void* _scintillaSecondHandle;
};

struct ShortcutKey
{
    bool  _isCtrl;
    bool  _isAlt;
    bool  _isShift;
    bool  _isKeyDown;
    UCHAR _key;
};

struct SCNotificationMin
{
    NMHDR nmhdr;
};

typedef void (*PFUNCPLUGINCMD)();

struct FuncItem
{
    wchar_t        _itemName[64];
    PFUNCPLUGINCMD _pFunc;
    int            _cmdID;
    bool           _init2Check;
    ShortcutKey*   _pShKey;
};
