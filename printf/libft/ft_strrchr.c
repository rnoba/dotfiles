#include "libft.h"

char    *ft_strrchr(const char *s, int c)
{
    size_t  len_s;

    len_s = ft_strlen(s) + 1;
    while(--len_s)
    {
        if (s[len_s] == (char) c)
            return (char *)&s[len_s];
    }
    if (s[len_s] == (char) c)
            return (char *)&s[len_s];
    return (NULL);
}
