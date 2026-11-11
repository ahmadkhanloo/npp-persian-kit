/*
 *  PersianKit for Notepad++  -  RTL + Vazirmatn font for Persian documents
 *  ---------------------------------------------------------------------------
 *  Commands
 *    - Persian mode (RTL + Vazirmatn)   : apply both to the current document
 *    - Toggle RTL / LTR                 : flip Scintilla's bidirectional mode
 *    - Apply Vazirmatn font             : set the font of every style of the doc
 *    - Auto Persian for .md/.txt        : remembers the choice, applies on open
 *    - About
 *
 *  The plugin only touches the *editor* (Scintilla styles + text direction).
 *  Markdown *rendering* is not part of this plugin; the kit ships an RTL /
 *  Vazirmatn stylesheet for the third-party "Markdown Panel" plugin.
 *
 *  License: GNU GPL v3.0 (see LICENSE).  Font: Vazirmatn (OFL 1.1).
 */
#include <windows.h>
#include <stdio.h>
#include <wchar.h>
#include <string>
#include "npp_api.h"

#define PLUGIN_NAME L"PersianKit"

enum CmdId
{
    CMD_PERSIAN_MODE = 0,
    CMD_TOGGLE_RTL,
    CMD_APPLY_FONT,
    CMD_AUTO_MD,
    CMD_JSON_FORMAT,
    CMD_JSON_FOLD,
    CMD_ABOUT,
    CMD_COUNT
};

/* ---------------------------------------------------------------- globals */
static NppData   g_npp;
static FuncItem  g_funcs[CMD_COUNT];
static ShortcutKey g_skRtl = { false, true, true, true, 0x52 };   /* R */   /* Alt+Shift+R */

static bool  g_autoMd      = true;    /* auto-apply for .md/.markdown/.txt */
static bool  g_rtlOnApply  = true;    /* Persian mode turns RTL on         */
static int   g_fontSize    = 12;
static int   g_jsonIndent  = 2;    /* spaces per level when the document does not use tabs */
static char  g_fontFace[64] = "Vazirmatn";
static wchar_t g_iniPath[MAX_PATH] = L"";
static bool  g_dwWarned    = false;

/* ---------------------------------------------------------------- helpers */
static HWND CurrentSci()
{
    int which = 0;
    SendMessage((HWND)g_npp._nppHandle, NPPM_GETCURRENTSCINTILLA, 0, (LPARAM)&which);
    return (which == 0) ? (HWND)g_npp._scintillaMainHandle
                        : (HWND)g_npp._scintillaSecondHandle;
}

static LRESULT Sci(HWND h, UINT msg, WPARAM wp = 0, LPARAM lp = 0)
{
    return ::SendMessage(h, msg, wp, lp);
}

/* extension of the current document, lowercase, without the dot */
static void CurrentExtension(wchar_t* out, int cch)
{
    out[0] = L'\0';
    if (!g_npp._nppHandle) return;
    SendMessage((HWND)g_npp._nppHandle, NPPM_GETEXTPART, (WPARAM)cch, (LPARAM)out);
    CharLowerBuffW(out, (DWORD)wcslen(out));
}

static bool IsPersianDocExtension(const wchar_t* ext)
{
    static const wchar_t* list[] = { L"md", L"markdown", L"mdown", L"mkd", L"mdwn",
                                     L"mdtxt", L"mdtext", L"txt" };
    for (int i = 0; i < (int)(sizeof(list) / sizeof(list[0])); ++i)
    {
        if (wcscmp(ext, list[i]) == 0) return true;
    }
    return false;
}

static bool IsUtf8(HWND sci)
{
    return Sci(sci, SCI_GETCODEPAGE) == SC_CP_UTF8;
}

/* ------------------------------------------------------------ settings ini */
static void BuildIniPath()
{
    wchar_t dir[MAX_PATH] = L"";
    if (g_npp._nppHandle)
        SendMessage((HWND)g_npp._nppHandle, NPPM_GETPLUGINSCONFIGDIR, MAX_PATH, (LPARAM)dir);
    if (!dir[0]) return;

    const wchar_t* file = L"\\NppPersianKit.ini";
    size_t n = wcslen(dir);
    if (n + wcslen(file) + 1 >= MAX_PATH) return;
    wcscpy_s(g_iniPath, MAX_PATH, dir);
    wcscat_s(g_iniPath, MAX_PATH, file);

    if (GetFileAttributesW(g_iniPath) == INVALID_FILE_ATTRIBUTES)
    {
        /* create it on first run so the user can edit it */
        WritePrivateProfileStringW(L"PersianKit", L"AutoPersianForMarkdown", L"1", g_iniPath);
        WritePrivateProfileStringW(L"PersianKit", L"TurnRtlOn", L"1", g_iniPath);
        WritePrivateProfileStringW(L"PersianKit", L"FontFace", L"Vazirmatn", g_iniPath);
        WritePrivateProfileStringW(L"PersianKit", L"FontSize", L"12", g_iniPath);
        WritePrivateProfileStringW(L"PersianKit", L"JsonIndentWidth", L"2", g_iniPath);
    }
}

static void LoadSettings()
{
    if (!g_iniPath[0]) BuildIniPath();
    if (!g_iniPath[0]) return;

    g_autoMd     = GetPrivateProfileIntW(L"PersianKit", L"AutoPersianForMarkdown", 1, g_iniPath) != 0;
    g_rtlOnApply = GetPrivateProfileIntW(L"PersianKit", L"TurnRtlOn", 1, g_iniPath) != 0;
    g_fontSize   = GetPrivateProfileIntW(L"PersianKit", L"FontSize", 12, g_iniPath);
    g_jsonIndent = GetPrivateProfileIntW(L"PersianKit", L"JsonIndentWidth", 2, g_iniPath);

    wchar_t face[64] = L"";
    GetPrivateProfileStringW(L"PersianKit", L"FontFace", L"Vazirmatn", face, 64, g_iniPath);
    WideCharToMultiByte(CP_UTF8, 0, face, -1, g_fontFace, sizeof(g_fontFace), NULL, NULL);
}

static void SaveSettings()
{
    if (!g_iniPath[0]) return;
    WritePrivateProfileStringW(L"PersianKit", L"AutoPersianForMarkdown", g_autoMd ? L"1" : L"0", g_iniPath);
    WritePrivateProfileStringW(L"PersianKit", L"TurnRtlOn", g_rtlOnApply ? L"1" : L"0", g_iniPath);
    wchar_t face[64] = L"";
    MultiByteToWideChar(CP_UTF8, 0, g_fontFace, -1, face, 64);
    WritePrivateProfileStringW(L"PersianKit", L"FontFace", face, g_iniPath);
    wchar_t sz[16];
    swprintf_s(sz, 16, L"%d", g_fontSize);
    WritePrivateProfileStringW(L"PersianKit", L"FontSize", sz, g_iniPath);
    swprintf_s(sz, 16, L"%d", g_jsonIndent);
    WritePrivateProfileStringW(L"PersianKit", L"JsonIndentWidth", sz, g_iniPath);
}

/* ------------------------------------------------------- DirectWrite guard
 * Scintilla's bidirectional support is not available while Notepad++ runs in
 * DirectWrite mode, so RTL silently does nothing there.  Detect it from
 * config.xml (the parent of the plugin config folder) and warn once.        */
static bool DirectWriteIsOn()
{
    if (!g_iniPath[0]) return false;

    /* ...\Notepad++\plugins\config\NppPersianKit.ini  ->  ...\Notepad++ */
    wchar_t cfgDir[MAX_PATH] = L"";
    wcscpy_s(cfgDir, MAX_PATH, g_iniPath);
    for (int i = 0; i < 3; ++i)          /* strip file, "config", "plugins" */
    {
        wchar_t* slash = wcsrchr(cfgDir, L'\\');
        if (!slash) return false;
        *slash = L'\0';
    }

    wchar_t path[MAX_PATH] = L"";
    _snwprintf_s(path, MAX_PATH, _TRUNCATE, L"%s\\config.xml", cfgDir);

    HANDLE h = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return false;

    char  buf[8192] = { 0 };
    DWORD read = 0;
    ReadFile(h, buf, sizeof(buf) - 1, &read, NULL);
    CloseHandle(h);
    buf[read] = '\0';

    return strstr(buf, "writeTechnologyEngine=\"1\"") != NULL;
}

static void WarnAboutDirectWriteOnce()
{
    if (g_dwWarned) return;
    if (!DirectWriteIsOn()) return;
    g_dwWarned = true;

    MessageBoxW(NULL,
        L"Right-to-left text needs Notepad++'s classic rendering engine.\n\n"
        L"Settings > Preferences > MISC > clear \"DirectWrite (Direct2D)\" \n"
        L"and restart Notepad++.  (The installer kit does this for you.)",
        PLUGIN_NAME L" - DirectWrite is on",
        MB_ICONINFORMATION | MB_OK);
}

/* ------------------------------------------------------------- operations */
static void ApplyFont(bool quiet)
{
    HWND sci = CurrentSci();
    if (!sci) return;

    for (int style = 0; style <= STYLE_MAX; ++style)
    {
        Sci(sci, SCI_STYLESETFONT, (WPARAM)style, (LPARAM)g_fontFace);
        Sci(sci, SCI_STYLESETSIZE, (WPARAM)style, (LPARAM)g_fontSize);
    }
    if (!quiet)
        MessageBoxW(NULL, L"Vazirmatn applied to the current document.", PLUGIN_NAME, MB_ICONINFORMATION | MB_OK);
}

static void SetRtl(bool on, bool quiet)
{
    HWND sci = CurrentSci();
    if (!sci) return;

    if (on && !IsUtf8(sci))
    {
        if (!quiet)
            MessageBoxW(NULL,
                L"Bidirectional text needs a UTF-8 document.\n\n"
                L"Encoding > Convert to UTF-8, then try again.",
                PLUGIN_NAME, MB_ICONWARNING | MB_OK);
        return;
    }

    Sci(sci, SCI_SETBIDIRECTIONAL, on ? SC_BIDIRECTIONAL_R2L : SC_BIDIRECTIONAL_DISABLED);

    if (on && Sci(sci, SCI_GETBIDIRECTIONAL) != SC_BIDIRECTIONAL_R2L)
        WarnAboutDirectWriteOnce();
}

static void ToggleRtl()
{
    HWND sci = CurrentSci();
    if (!sci) return;
    bool rtlNow = Sci(sci, SCI_GETBIDIRECTIONAL) == SC_BIDIRECTIONAL_R2L;
    SetRtl(!rtlNow, false);
}

static void PersianMode()
{
    ApplyFont(true);
    if (g_rtlOnApply) SetRtl(true, true);
    WarnAboutDirectWriteOnce();
}

/* ------------------------------------------------------------ JSON helpers
 * A tiny, encoding-agnostic beautifier: it only inserts/removes whitespace
 * outside string literals, so UTF-8 (Persian) content is copied byte for byte.
 * Returns false when the text is not a single well-formed JSON value.        */
static bool FormatJsonText(const std::string& in, std::string& out, const std::string& unit)
{
    out.clear();
    out.reserve(in.size() + in.size() / 4);

    int  depth = 0;
    bool inString = false, escaped = false, anyToken = false;
    const size_t n = in.size();

    for (size_t i = 0; i < n; ++i)
    {
        const char c = in[i];

        if (inString)
        {
            out.push_back(c);
            if (escaped)          escaped = false;
            else if (c == '\\')   escaped = true;
            else if (c == '"')    inString = false;
            continue;
        }

        switch (c)
        {
        case '"':
            out.push_back(c);
            inString = true;
            anyToken = true;
            break;

        case '{':
        case '[':
        {
            size_t j = i + 1;
            while (j < n && (in[j] == ' ' || in[j] == '\t' || in[j] == '\r' || in[j] == '\n')) ++j;
            const char close = (c == '{') ? '}' : ']';
            if (j < n && in[j] == close)          /* empty object/array */
            {
                out.push_back(c);
                out.push_back(close);
                i = j;
            }
            else
            {
                out.push_back(c);
                ++depth;
                out.push_back('\n');
                for (int d = 0; d < depth; ++d) out += unit;
            }
            anyToken = true;
            break;
        }

        case '}':
        case ']':
            if (depth > 0) --depth;
            out.push_back('\n');
            for (int d = 0; d < depth; ++d) out += unit;
            out.push_back(c);
            anyToken = true;
            break;

        case ',':
            out.push_back(',');
            out.push_back('\n');
            for (int d = 0; d < depth; ++d) out += unit;
            anyToken = true;
            break;

        case ':':
            out.push_back(':');
            out.push_back(' ');
            anyToken = true;
            break;

        case ' ': case '\t': case '\r': case '\n':
            break;                                 /* collapse whitespace */

        default:
            out.push_back(c);
            anyToken = true;
            break;
        }
    }

    return anyToken && depth == 0 && !inString;
}

/* One indentation step for the current document:
 *   - documents that use real tabs  -> a TAB per level
 *   - everything else              -> JsonIndentWidth spaces per level (default 2) */
static std::string IndentUnitForDocument(HWND sci)
{
    if (Sci(sci, SCI_GETUSETABS) != 0)
        return std::string("\t");

    int width = g_jsonIndent;
    if (width < 1 || width > 16) width = 2;
    return std::string((size_t)width, ' ');
}

static void CmdJsonFormat()
{
    HWND sci = CurrentSci();
    if (!sci) return;

    const long len = (long)Sci(sci, SCI_GETLENGTH);
    if (len <= 0) return;

    std::string src((size_t)len + 1, '\0');
    Sci(sci, SCI_GETTEXT, (WPARAM)(len + 1), (LPARAM)&src[0]);
    src.resize((size_t)len);

    std::string pretty;
    if (!FormatJsonText(src, pretty, IndentUnitForDocument(sci)))
    {
        MessageBoxW(NULL,
            L"This document does not look like valid JSON, so it was left untouched.",
            PLUGIN_NAME L" - Format JSON", MB_ICONWARNING | MB_OK);
        return;
    }
    if (pretty == src) return;

    Sci(sci, SCI_BEGINUNDOACTION);
    Sci(sci, SCI_SETSEL, 0, (LPARAM)len);
    Sci(sci, SCI_REPLACESEL, 0, (LPARAM)pretty.c_str());
    Sci(sci, SCI_ENDUNDOACTION);
}

static void CmdJsonFoldAll()
{
    HWND sci = CurrentSci();
    if (!sci) return;
    Sci(sci, SCI_FOLDALL, SC_FOLDACTION_CONTRACT);
}

/* --------------------------------------------------------------- commands */
static void CmdPersianMode() { PersianMode(); }

static void CmdToggleRtl()   { ToggleRtl(); }

static void CmdApplyFont()   { ApplyFont(false); }

static void CmdAutoMd()
{
    g_autoMd = !g_autoMd;
    SaveSettings();
    if (g_npp._nppHandle)
        SendMessage((HWND)g_npp._nppHandle, NPPM_SETMENUITEMCHECK,
                    (WPARAM)g_funcs[CMD_AUTO_MD]._cmdID, (LPARAM)(g_autoMd ? 1 : 0));

    wchar_t ext[32] = L"";
    CurrentExtension(ext, 32);
    if (g_autoMd && IsPersianDocExtension(ext))
        PersianMode();
}

static void CmdAbout()
{
    MessageBoxW(NULL,
        L"PersianKit 1.1.1\n"
        L"RTL (right-to-left) editing, Vazirmatn font, and small JSON helpers.\n\n"
        L"Commands (also in Settings > Shortcut Mapper > Plugin commands):\n"
        L"  - Persian mode (RTL + Vazirmatn)\n"
        L"  - Toggle RTL / LTR            (default Alt+Shift+R)\n"
        L"  - Apply Vazirmatn font\n"
        L"  - Auto Persian for .md/.txt\n"
        L"  - JSON: format (2 spaces)     (whole document, undoable)\n"
        L"  - JSON: fold all\n\n"
        L"JSON indent: one TAB per level when the document uses tabs,\n"
        L"             otherwise JsonIndentWidth spaces (default 2).\n\n"
        L"Settings: %APPDATA%\\Notepad++\\plugins\\config\\NppPersianKit.ini\n"
        L"RTL requires: DirectWrite off + UTF-8 document.\n\n"
        L"Font \"Vazirmatn\" by Saber Rastikerdar (OFL 1.1).\n"
        L"Plugin code: GNU GPL v3.",
        PLUGIN_NAME, MB_ICONINFORMATION | MB_OK);
}

/* ------------------------------------------------------------- plugin ABI */
extern "C" __declspec(dllexport) void setInfo(NppData notepadPlusData)
{
    g_npp = notepadPlusData;
    BuildIniPath();
    LoadSettings();

    FuncItem items[CMD_COUNT] = {
        { L"Persian mode (RTL + Vazirmatn)", CmdPersianMode, 0,        false, NULL },
        { L"Toggle RTL / LTR",               CmdToggleRtl,   1,        false, &g_skRtl },
        { L"Apply Vazirmatn font",           CmdApplyFont,   2,        false, NULL },
        { L"Auto Persian for .md/.txt",      CmdAutoMd,      3,        true,  NULL },
        { L"JSON: format (2 spaces)",        CmdJsonFormat,  4,        false, NULL },
        { L"JSON: fold all",                 CmdJsonFoldAll, 5,        false, NULL },
        { L"About",                          CmdAbout,       6,        false, NULL },
    };

    for (int i = 0; i < CMD_COUNT; ++i)
    {
        g_funcs[i] = items[i];
        g_funcs[i]._cmdID = i;
    }
    g_funcs[CMD_AUTO_MD]._init2Check = g_autoMd;
}

extern "C" __declspec(dllexport) const wchar_t* getName()
{
    return PLUGIN_NAME;
}

extern "C" __declspec(dllexport) FuncItem* getFuncsArray(int* nbF)
{
    *nbF = CMD_COUNT;
    return g_funcs;
}

extern "C" __declspec(dllexport) BOOL isUnicode()
{
    return TRUE;
}

extern "C" __declspec(dllexport) void beNotified(SCNotificationMin* notify)
{
    if (!notify) return;

    switch (notify->nmhdr.code)
    {
    case NPPN_READY:
        if (g_npp._nppHandle)
            SendMessage((HWND)g_npp._nppHandle, NPPM_SETMENUITEMCHECK,
                        (WPARAM)g_funcs[CMD_AUTO_MD]._cmdID, (LPARAM)(g_autoMd ? 1 : 0));
        if (g_autoMd)
        {
            wchar_t ext[32] = L"";
            CurrentExtension(ext, 32);
            if (IsPersianDocExtension(ext)) PersianMode();
        }
        break;

    case NPPN_BUFFERACTIVATED:
        if (g_autoMd)
        {
            wchar_t ext[32] = L"";
            CurrentExtension(ext, 32);
            if (IsPersianDocExtension(ext))
            {
                ApplyFont(true);
                if (g_rtlOnApply) SetRtl(true, true);
            }
        }
        break;

    default:
        break;
    }
}

extern "C" __declspec(dllexport) LRESULT messageProc(UINT /*Message*/, WPARAM /*wParam*/, LPARAM /*lParam*/)
{
    return TRUE;
}

BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID)
{
    return TRUE;
}
