#include "./libft/libft.h"
#include "./ft_printf.h"
#include "unistd.h"
#include "stdarg.h"

# define FLAGS              "0+#- ." 
# define HEX                "0123456789abcdef" 
# define U_HEX              "0123456789ABCDEF" 
# define HEX_PREFIX         "0x"
# define U_HEX_PREFIX       "0X"

# define CHAR               10
# define STRING             11 
# define DECIMAL            12
# define HEXADECIMAL        13
# define U_HEXADECIMAL      14
# define POINTER            15
# define U_DECIMAL          16
# define PER                17

typedef struct s_format {
    int     lhs;
    int     rhs;
    // Define which flags are being used for 
    // the current variable argument in the correct order.
    char    flags[7];
    char    *prefix;
    int     type;
    int     offset;
}   t_format;

char    *ft_add_prefix(char *str, char *prefix)
{
    char    *ret;

    ret = ft_strjoin(prefix, str);
    free(str);
    return (ret);
}

int ft_format_type(const char *str)
{
    if (!str)
        return (0);
    if (*str == 'c')
        return (CHAR);
    else if(*str == 's')
        return (STRING);
    else if(*str == 'x')
        return (HEXADECIMAL);
    else if(*str == 'X')
        return (U_HEXADECIMAL);
    else if(*str == 'p')
        return (POINTER);
    else if(*str == 'i' || *str == 'd')
        return (DECIMAL);
    else if(*str == 'u')
        return (U_DECIMAL);
    else if(*str == '%')
        return (PER);
    return (0);
}

// I'll create a flag list inside the struct and populate
// it while i'm parsing them.
// so it'll be more easy to handle in order.
t_format    *ft_init_format(void)
{
    t_format    *f;

    f = malloc(sizeof(t_format));
    f->lhs = -1;
    f->rhs = -1;
    f->offset = 0;
    ft_bzero(f->flags, 7);
    return (f);
}

char    *ft_itoa_base(long nbr, const char *base)
{
    char    *tab;
    long    nbr_l;
    size_t  len;
    size_t  blen;

    len = 0;
    if (nbr == 0)
        len = 1;
    nbr_l = nbr;
    blen = ft_strlen(base);
    while (nbr_l)
    {
        len++;
        nbr_l /= blen;
    }
    tab = malloc(sizeof(char) * (len + 1));
    ft_bzero(tab, len + 1);
    while (len--)
    {
        tab[len] = base[nbr%blen];
        nbr /= blen;
    }
    return (tab);
}

char    *ft_sfc(char c)
{
    char    *str;

    str = ft_strdup("1");
    str[0] = c;
    return (str);
}

char    *ft_parse_type(va_list *ptr, const char *str)
{
    char    *arg;
    void    *v_arg;

    if (!str)
        return (ft_strdup(""));
    if (*str == 'c')
        return (ft_sfc(va_arg(*ptr, int)));
    else if(*str == 's')
    {
        arg = va_arg(*ptr, char *);
        if (!arg)
            return (ft_strdup("(null)"));
        return (ft_strdup(arg));
    }
    else if(*str == 'x')
        return (ft_itoa_base(va_arg(*ptr, unsigned int), HEX));
    else if(*str == 'X')
        return (ft_itoa_base(va_arg(*ptr, unsigned int), U_HEX));
    else if(*str == 'p')
    {
        v_arg = va_arg(*ptr, void *);
        if (!(long)v_arg)
            return (ft_strdup("(nil)"));
        return (ft_add_prefix(ft_itoa_base((long)v_arg, HEX), HEX_PREFIX));
    }
    else if(*str == 'd' || *str == 'i')
        return (ft_itoa(va_arg(*ptr, int)));
    else if(*str == 'u')
        return (ft_itoa_base(va_arg(*ptr, unsigned int), "0123456789"));
    else if(*str == '%')
        return (ft_strdup("%"));
    return (0);
}

t_format    *ft_parse_format(va_list *ptr, const char *str)
{
    int         idx;
    int         flag;
    t_format    *f;

    // printf("\nstr: %s\n", str);
    f = ft_init_format();
    idx = 0;
    flag = -1;
    while (!(0==ft_strlen(f->flags) && str[idx] == '.') && ft_strchr(FLAGS, str[idx]))
    {
        if (str[idx] == '.' && f->flags[flag] == '0')
            f->lhs = 0; 
        else if(str[idx] == '.' && f->flags[flag] == '-')
            f->lhs = 0; 
        if (!ft_strchr(f->flags, str[idx]))
            f->flags[++flag] = str[idx];
        idx++;
    }
    if (f->lhs < 0 && ft_isdigit(str[idx]))
        f->lhs = ft_atoi(&str[idx]);
    else
        f->rhs = ft_atoi(&str[idx]);
    while (ft_isdigit(str[idx]))
        idx++;
    while (ft_strchr(FLAGS, str[idx]))
    {
        if (!ft_strchr(f->flags, str[idx]))
            f->flags[++flag] = str[idx];
        idx++;
    }
    if (ft_isdigit(str[idx]))
        f->rhs = ft_atoi(&str[idx]);
    while (ft_isdigit(str[idx]))
        idx++;
    // return prefix str from here
    f->prefix = ft_parse_type(ptr, &str[idx]);
    f->type = ft_format_type(&str[idx]);
    if (!f->type || !f->prefix)
        return (NULL);
    f->offset = idx;
    // printf("type: %d\n", f->type);
    // printf("off: %d\n", f->offset);
    // printf("left: %d\n", f->lhs);
    // printf("right: %d\n", f->rhs);
    //printf("right: %s\n", f->prefix);
    //printf("flags: %s (%d)\n", f->flags, (int)ft_strlen(f->flags));
    // printf("flags: %s (%d)\n", f->flags, (int)ft_strlen(f->flags));
    // printf("prefix: %s\n", f->prefix);
    // printf("\n");
    if (f->rhs < 0)
        f->rhs = 0; 
    else if (f->lhs < 0)
        f->lhs = 0; 
    if (f->type != CHAR && f->prefix[0] == '%')
        f->lhs = 0;
    return (f);
}

static int  ft_pad(char c, int n)
{
    int len;

    len = 0;
    while(--n > 0)
        len += write(1, &c, 1);
    return (len);
}

int ft_print(int s_signal, char *str, int left_pad, int dot_pad, int pad_dir, char pad_char, int offset, int signal)
{
    int len;
    int sub;

    len = 0;
    sub = 0;
    if (signal)
        sub = 1;
    if (str[0] == '%')
    {
        if (pad_dir)
        {
            len += ft_pad(pad_char, left_pad - sub);
            len += (write(1, "%", 1));
        }
        else
        {
            len += (write(1, "%", 1));
            len += ft_pad(pad_char, left_pad - sub);
        }
        return (len);
    }
    if (pad_dir)
    {
        len += ft_pad(pad_char, left_pad - sub);
        if (signal)
            if (str[0] != '-')
                len += ft_pad(signal, 2);
        if (s_signal)
            len += write(1, "-", 1);
        if (dot_pad)
            len += ft_pad('0', dot_pad - sub);
        len += write(1, str, ft_strlen(str) + offset);
    }
    else if (!pad_dir)
    {
        if (s_signal)
            len += write(1, "-", 1);
        if (signal)
            if (str[0] != '-')
                len += ft_pad(signal, 2);
        if (dot_pad)
            len += ft_pad('0', dot_pad - sub);
        len += write(1, str, ft_strlen(str) + offset);
        len += ft_pad(pad_char, left_pad);
    }
    return (len);
}

int ft_handle_format(t_format *format)
{
    int     len;
    char    prev_flag;
    size_t  flag_count;
    int     pad_left;
    char    signal;
    int     pad_dot;
    int     pad_char;
    int     pad_dir;
    int     off;
    int     offset;
    int     s_signal;
    char    *prefix_str;

    len = 0;
    off = 0;
    s_signal = 0;
    offset = 0;
    signal = 0;
    pad_char = ' ';
    prev_flag = 0;
    pad_left = 0;
    pad_dot = 0;
    flag_count = ft_strlen(format->flags);
    prefix_str = format->prefix;
    if (format->type == CHAR && *prefix_str == 0)
        pad_left = -1;
    if (format->lhs)
        pad_left += 1 + format->lhs - ft_strlen(prefix_str);
    pad_dir = (format->lhs && !flag_count);
    if (format->type == CHAR && *prefix_str == 0)
        off = 1;
    if(flag_count)
    {
        while (flag_count--)
        {
            char    *tmp;
            if (format->flags[flag_count] == '0')
            {
                int t;
                if (!prev_flag && !(format->type != STRING && (pad_dot > 0 && pad_left > 0)))
                {
                    pad_dir = 1;
                    pad_dot = pad_left;
                    t = pad_left;
                    pad_left = 0;
                }
                if (format->type != STRING && prefix_str[0] == '-')
                {
                    s_signal = 1;
                    offset = 1;
                }
                if (format->type == STRING || format->type == CHAR)
                {
                    pad_char = ' ';
                    pad_dot = 0;
                    pad_left = t;
                }
                prev_flag = '0';
            }
            else if(format->flags[flag_count] == '.')
            {
                if ((format->type != STRING  && format->type != CHAR) && (!format->lhs && !format->rhs))
                {
                    tmp = prefix_str;
                    prefix_str = ft_strdup("");
                    free(tmp);
                }
                if ((format->type != STRING  && format->type != CHAR) && format->lhs && prefix_str[0] == '0')
                {
                    tmp = prefix_str;
                    prefix_str = ft_strdup("");
                    if (format->lhs)
                        pad_left = 1 + format->lhs - ft_strlen(prefix_str);
                    free(tmp);
                }
                if (format->type != STRING && prefix_str[0] == '-')
                {
                    s_signal = 1;
                    offset = 1;
                }
                pad_dot = 1 + format->rhs - ft_strlen(prefix_str + offset);
                if (pad_dot < 0)
                    pad_dot = 0;
                if (pad_left > pad_dot && format->type != STRING)
                    pad_left = 1 + pad_left - pad_dot;
                if (format->type != STRING && format->rhs < (int)ft_strlen(prefix_str))
                    pad_left--;
                else if(format->type == STRING)
                {
                    int prev_len;
                    pad_dot = 0;
                    tmp = prefix_str;
                    prev_len = ft_strlen(prefix_str);
                    if (ft_strncmp(prefix_str, "(null)", ft_strlen(prefix_str)) == 0 && (int)ft_strlen(prefix_str) > format->rhs)
                        prefix_str = ft_strdup("");
                    else
                        prefix_str = ft_substr(prefix_str, 0, format->rhs);
                    if (prev_len > format->rhs)
                        pad_left = 1 + format->lhs - ft_strlen(prefix_str);
                    free(tmp);
                }
                printf("%d, %d\n", pad_left, pad_dot);
                if (format->lhs < format->rhs)
                    pad_left = 0;
                prev_flag = '.';
                pad_dir = 1;
            }
            else if (format->flags[flag_count] == '-')
            {
                pad_dir = 0;
                pad_char = ' ';
            }
            else if (format->type != STRING && (format->flags[flag_count] == ' ' || format->flags[flag_count] == '+'))
                signal = format->flags[flag_count];
            else if (format->flags[flag_count] == '#')
            {
                if (*prefix_str != '0')
                {
                    if (format->type == HEXADECIMAL)
                        prefix_str = ft_add_prefix(prefix_str, HEX_PREFIX);
                    else if (format->type == U_HEXADECIMAL)
                        prefix_str = ft_add_prefix(prefix_str, U_HEX_PREFIX);
                }
            }
        }
    }
    len += ft_print(s_signal, prefix_str + offset, pad_left, pad_dot, pad_dir, pad_char, off, signal);
    free(prefix_str);
    return (len);
}

int ft_printf(const char *str, ...)
{
    size_t      idx;
    int         len;
    va_list     ptr;
    t_format    *format;

    idx = 0;
    len = 0;
    va_start(ptr, str);
    while (str[idx])
    {
        if (str[idx] == '%')
        {
            idx++;
            format = ft_parse_format(&ptr, &str[idx]);
            if (format)
            {
                len += ft_handle_format(format);
                idx += format->offset;
                free(format);
            }
        }
        else
            len += write(1, &str[idx], 1);
        idx++;
    }
    va_end(ptr);
    return (len);
}
