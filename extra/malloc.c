#include <stdlib.h>

int main()
{
    void* ptr;

    ptr = malloc(32);

    free(ptr);

    return 0;
}
