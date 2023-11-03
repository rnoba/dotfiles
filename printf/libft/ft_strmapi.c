#include "libft.h"

char    *ft_strmapi(char const *s, char (*f)(unsigned int, char))
{
    size_t  len_s;
    char    *r;
    size_t  idx;

    if(!s)
        return (NULL);
    len_s = ft_strlen(s);
    r = malloc(sizeof(char) * (1 + len_s));
    idx = 0;
    while (idx < len_s)
    {
        r[idx] = f(idx, s[idx]);
        idx++;
    }
    r[idx] = '\0';
    return (r);
}
