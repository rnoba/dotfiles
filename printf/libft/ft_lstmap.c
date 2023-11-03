#include "libft.h"

t_list  *ft_lstmap(t_list *lst, void *(*f)(void *), void (*del)(void *))
{
    t_list *tab;
    t_list *new_lst;
    t_list *element;

    tab = lst;
    new_lst = NULL;
    while (tab)
    {
        element = ft_lstnew(f(tab->content));
        if (!element)
        {
            ft_lstclear(&new_lst, del);
            return (NULL);
        }
        ft_lstadd_back(&new_lst, element);
        tab = tab->next;
    }
    return (new_lst);
}

