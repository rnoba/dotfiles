#include "../libft.h"

int main(void)
{
    char str[] = "testing";
    printf("%s", ft_strchr(str, 't' + 256));
    return (0);
}
