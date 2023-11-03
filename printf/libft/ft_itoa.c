#include "libft.h"

static int  ft_arr_len(int c)
{
    int len;

    len = 0;
    if (c <= 0)
        len = 1;
    while(c)
    {
        len++;
        c /= 10;
    }
    return (len);
}

char    *ft_itoa(int c)
{
    unsigned int    u_c;
    char    *tab;
    int     len; 

    len = ft_arr_len(c);
    u_c = c;
    tab = malloc(sizeof(char) * (len + 1));
    if(!tab)
        return (NULL);
    if(c < 0)
        u_c = -c;
    ft_bzero(tab, len + 1);
    while (len--)
    {
        tab[len] = '0' + u_c % 10;
        u_c /= 10;
    }
    if (c < 0)
        tab[0] = '-';
    return (tab);
}
