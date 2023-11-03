#include "libft.h"

void    *ft_memmove(void *dest, const void *src, size_t size)
{
    char        *dest_p;
    const char  *src_p;

    dest_p = dest;
    src_p = src;
    if (dest > src)
        while (size--)
            dest_p[size] = src_p[size];
    else
        ft_memcpy(dest, src, size);
    return (dest);
}
