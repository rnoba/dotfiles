#include "libft.h"

void    *ft_memchr(const void *s, int c, size_t n)
{
    size_t  idx;
    const unsigned char   *s_p;

    s_p = s;
    idx = 0;
    while (idx < n)
    {
        if (s_p[idx] == (unsigned char) c)
            return (void *)&(s_p[idx]);
        idx++;
    }
    return (NULL);
}
