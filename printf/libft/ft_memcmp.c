#include "libft.h"

int ft_memcmp(const void *s1, const void *s2, size_t len)
{
    const unsigned char   *s1_p;
    const unsigned char   *s2_p;
    size_t  idx;

    if (!len)
        return (0);
    s1_p = s1;
    s2_p = s2;
    idx = 0;
    while (idx < len)
    {
        if(s1_p[idx] != s2_p[idx])
            return (s1_p[idx] - s2_p[idx]);
        idx++;
    }
    return (0);
}
