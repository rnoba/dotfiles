#include "libft.h"

void    *ft_memcpy(void *dest, const void *src, size_t size)
{
    char        *dest_p;
    const char  *src_p;
    size_t      idx;

    if (!src && !dest)
        return (0);
    dest_p = dest;
    src_p = src;
    idx = 0;
    while (idx < size)
    {
        dest_p[idx] = src_p[idx];
        idx++;
    }
    return (dest);
}
