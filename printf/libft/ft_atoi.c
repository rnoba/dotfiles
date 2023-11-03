#include "libft.h"

static int  ft_isspace(char c)
{
    if (c == '\t'
       || c == '\n'
       || c == '\r'
       || c == '\f'
       || c == ' '
       || c == '\v')
        return (1);
    return (0);
}

static int  ft_issign(char c)
{
    if (c == '-' || c == '+')
        return (1);
    return (0);
}

int ft_atoi(const char *nptr)
{
    int s;
    int result;

    s = 1;
    result = 0;
    while (ft_isspace(*nptr))
        nptr++;
    if (ft_issign(*nptr))
    {
        if (*nptr == '-')
            s = -1;
        nptr++;
    }
    while (ft_isdigit(*nptr))
    {
        result = result * 10 + *nptr - '0';
        nptr++;
    }
    return (result * s);
}
