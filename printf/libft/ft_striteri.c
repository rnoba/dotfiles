#include "libft.h"

void    ft_striteri(char *s, void (*f)(unsigned int, char*))
{
    size_t  len_s;
    size_t  idx;

    if(!s)
        return ;
    len_s = ft_strlen(s);
    idx = 0;
    while (idx < len_s)
    {
        f(idx, &s[idx]);
        idx++;
    }
}
