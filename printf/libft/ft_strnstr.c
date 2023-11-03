#include "libft.h"

char    *ft_strnstr(const char *haystack, const char *needle, size_t len)
{
    size_t  len_n;

    if (!needle)
        return ((char *)haystack);
    len_n = ft_strlen(needle);
    while (*haystack && len >= len_n && ft_strncmp(haystack, needle, len_n))
    {
        len--;
        haystack++;
    }
    if (len >= len_n && 0 == ft_strncmp(haystack, needle, len_n))
        return (char *)haystack; 
    return (NULL);
}
