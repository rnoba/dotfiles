#include "libft.h"

size_t  ft_strlcpy(char *dest, const char *src, size_t size)
{
    size_t len_s;

    len_s = ft_strlen(src);
    if (size > len_s)
        ft_memcpy(dest, src, len_s + 1);
    else if(size)
    {
        ft_memcpy(dest, src, size - 1);
        dest[size - 1] = '\0';
    }
    return (len_s);
}
