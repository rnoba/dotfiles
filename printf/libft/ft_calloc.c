#include "libft.h"

void    *ft_calloc(size_t nmemb, size_t size)
{
    void    *m;
    size_t  l;

    l = nmemb * size;
    m = malloc(l);
    if(!m)
        return (NULL);
    ft_bzero(m, l);
    return (m);
}
