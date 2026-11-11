// Offline test for the PersianKit JSON beautifier (not part of the plugin DLL).
// Build:  build\test\run-test.bat   (uses the same MSVC toolchain)
#include <stdio.h>
#include <string>
#include "../../src/PersianKit.cpp"

static void Show(const char* label, const std::string& text, const char* unit = "  ")
{
    std::string out;
    const bool ok = FormatJsonText(text, out, std::string(unit));
    printf("=== %s : %s\n", label, ok ? "valid" : "INVALID");
    if (ok) printf("%s\n", out.c_str());
    printf("\n");
}

int main(int argc, char** argv)
{
    Show("compact",
         "{\"app\":\"x\",\"features\":{\"a\":true,\"b\":false},"
         "\"providers\":[{\"name\":\"Zharfa\",\"timeout\":120},{\"name\":\"Local\",\"timeout\":30}],"
         "\"empty\":{},\"list\":[],\"note\":\"text\",\"esc\":\"a\\\"b\\\\c\"}");
    Show("broken", "{\"bad\": [1,2}");
    Show("scalar", "  42  ");
    Show("deep", "{\"nested\":{\"deep\":{\"deeper\":[1,[2,[3]]]}}}");
    Show("array root", "[1,{\"a\":[]},[]]");
    Show("tabs", "{\"a\":{\"b\":[1,2]}}", "\t");

    if (argc > 1)
    {
        FILE* f = fopen(argv[1], "rb");
        if (f)
        {
            std::string data;
            char buf[4096];
            size_t n;
            while ((n = fread(buf, 1, sizeof(buf), f)) > 0) data.append(buf, n);
            fclose(f);
            Show(argv[1], data);
        }
    }
    return 0;
}
