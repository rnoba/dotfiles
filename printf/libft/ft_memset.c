#include "libft.h"

void    *ft_memset(void *s, int c, size_t n)
{
    char        *s_p;
    size_t      idx;

    s_p = s;
    idx = -1;
    while (++idx < n)
        s_p[idx] = (unsigned char) c;
    return (s);
}
