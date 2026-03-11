#include <signal.h>
#include <unistd.h>
#include <stdlib.h>

void	ft_error(void)
{
	write(1, "Error\n", 6);
	exit(1);
}

void	check_args(int argc)
{
	if (argc != 3)
		ft_error();
}

int	ft_atoi_strict(char *str)
{
	int	result;

	result = 0;
	if (!(*str >= '0' && *str <= '9'))
		ft_error();
	while (*str >= '0' && *str <= '9')
		result = result * 10 + (*str++ - '0');
	if (*str && !(*str >= '0' && *str <= '9'))
		ft_error();
	return (result);
}

int	main(int argc, char **argv)
{
	int				pid;
	int				i;
	unsigned char	mask;

	check_args(argc);
	pid = ft_atoi_strict(argv[1]);
	i = 0;
	while (argv[2][i])
	{
		mask = 128;
		while (mask > 0)
		{
			if (argv[2][i] & mask)
				kill(pid, SIGUSR2);
			else
				kill(pid, SIGUSR1);
			usleep(100);
			mask >>= 1;
		}
		i++;
	}
	return (0);
}
