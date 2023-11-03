#include "libft.h"

void    ft_putnbr_fd(int n, int fd)
{
    unsigned int    n_u;
    
    n_u = n;
    if (n < 0)
    {
        ft_putchar_fd('-', fd);
        n_u = -n;
    }
    if (n_u > 9)
        ft_putnbr_fd(n_u / 10, fd);
    ft_putchar_fd((n_u % 10) + '0', fd);
}
