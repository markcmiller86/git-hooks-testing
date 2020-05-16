#include <foo.h>

using std::string;

int main()
{
    string foo;
    foo = "mark";
    int r = 0;
#ifdef DEBUG
    if (r == 0) abort();
#endif
    return 0;
}
