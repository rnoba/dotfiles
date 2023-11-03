#include "libft.h"

void    ft_lstadd_back(t_list **lst, t_list *n)
{
    t_list  *end;

    if (!(*lst))
        *lst = n;
    else
    {
        end = ft_lstlast(*lst);
        if (end)
            end->next = n;
    }
}
