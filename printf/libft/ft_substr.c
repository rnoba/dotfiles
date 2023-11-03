#include "libft.h"

char    *ft_substr(char const *s, unsigned int start, size_t len)
{
    char    *sub;
    size_t  len_s;

    len_s = ft_strlen(s);
    if (start > len_s)
        return (ft_strdup(""));
    if (len_s < (len + start))
        len = len_s - start;
    sub = malloc(sizeof(char) * (1 + len));
    if (!sub)
        return (NULL);
    ft_memcpy(sub, s + start, len);
    sub[len] = '\0';
    return (sub);
}
