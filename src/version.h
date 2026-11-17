/*
 *  version.h  -  the single source of truth for the PersianKit version.
 *  ---------------------------------------------------------------------
 *  Bump PK_VERSION_* here; everything else follows:
 *    - src/PersianKit.rc   -> the DLL version resource (visible in Explorer,
 *                             and read by the nppPluginList validator)
 *    - src/PersianKit.cpp  -> the About box
 *    - build/package.ps1   -> the zip names and the expected DLL version
 *
 *  The nppPluginList validator compares the four numeric parts of the DLL
 *  FILEVERSION with the "version" of the plugin list entry padded with
 *  zeroes, so MAJOR.MINOR.PATCH below must match that JSON value exactly.
 */
#ifndef PERSIANKIT_VERSION_H
#define PERSIANKIT_VERSION_H

#define PK_VERSION_MAJOR 1
#define PK_VERSION_MINOR 3
#define PK_VERSION_PATCH 1
#define PK_VERSION_BUILD 0

#define PK_VERSION_STR  "1.3.1"
#define PK_VERSION_WSTR L"1.3.1"

#endif /* PERSIANKIT_VERSION_H */
