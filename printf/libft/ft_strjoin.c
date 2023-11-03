#include "libft.h"

char    *ft_strjoin(char const *s1, char const *s2)
{
    char *j;
    size_t  len_s1;
    size_t  len_s2;

    len_s1 = ft_strlen(s1);
    len_s2 = ft_strlen(s2);
    j = malloc(sizeof(char) * (len_s1 + len_s2 + 1));
    if(!j)
        return (NULL);
    ft_memcpy(j, s1, len_s1);
    ft_memcpy(j + len_s1, s2, len_s2 + 1);
    return (j);
}
