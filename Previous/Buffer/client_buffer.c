#include <signal.h>
#include <unistd.h>
#include <stdlib.h>

void	ft_handler(int signum)
{
	(void)signum;
}

void	ft_error(void)
{
	write(1, "Error\n", 6);
	exit(1);
}

void	ft_check(int argc)
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

int	main(int num, char **arg)
{
	int				pid;
	int				i;
	unsigned char	mask;

	ft_check(num);
	signal(SIGUSR1, ft_handler);
	pid = ft_atoi_strict(arg[1]);
	i = 0;
	while (arg[2][i])
	{
		mask = 128;
		while (mask > 0)
		{
			if (arg[2][i] & mask)
				kill(pid, SIGUSR2);
			else
				kill(pid, SIGUSR1);
			pause();
			mask >>= 1;
		}
		i++;
	}
	write(1, "Message received.\n", 18);
	return (0);
}
