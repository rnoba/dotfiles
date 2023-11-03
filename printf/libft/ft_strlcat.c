#include "libft.h"

size_t  ft_strlcat(char *dest, const char *src, size_t size)
{
    size_t len_s;
    size_t len_d;

    len_s = ft_strlen(src);
    len_d = ft_strlen(dest);
    if (!size || len_d >= size)
        return (size + len_s);
    if (size - len_d > len_s)
        ft_memcpy(dest + len_d, src, len_s + 1);
    else
    {
        ft_memcpy(dest + len_d, src, size - len_d - 1);
        dest[size - 1] = '\0';
    }
    return (len_s + len_d);
}
