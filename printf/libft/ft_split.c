#include "libft.h"

static size_t   ft_strlen_d(char const *s, char c)
{
    size_t  len;

    len = 0;
    while (s[len] && s[len] != c)
        len++;
    return (len);
}

static size_t   ft_get_array_size(char const *s, char c)
{
    size_t  len;
    int in_word;

    len = 0;
    in_word = 1;
    if(!s)
        return (0);
    while (*s)
    {
        if (!in_word && *s == c)
        {
            in_word = 1;
            while(*s == c)
                s++;
        }
        if (in_word)
        {
            len++;
            in_word = 0;
        }
        s++;
    }
    return (len);
}

char    **ft_split(char const *s, char c)
{
    size_t  len_a;
    // char    *set; 
    char    *trim;
    char    *d;
    char    **split;
    size_t  idx;

    trim = ft_strtrim(s, &c);
    if(!trim)
        return (NULL);
    d = trim;
    len_a = ft_get_array_size(trim, c);
    split = malloc(sizeof(char *) * (1 + len_a));
    if(!split)
        return (NULL);
    idx = 0;
    while (*trim && idx < len_a)
    {
        split[idx] = ft_substr(trim, 0, ft_strlen_d(trim, c));
        while (*trim && *trim != c)
            trim++;
        while (*trim && *trim == c)
            trim++;
        idx++;
    }
    if(d)
        free(d);
    split[idx] = NULL;
    return (split);
}
