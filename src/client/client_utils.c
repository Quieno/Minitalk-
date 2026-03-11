
#include "client.h"

void	ft_error(void)
{
	write(2, "Error\n", 6);
	exit(1);
}

int	ft_atoi_strict(char *str)
{
	int	result;

	result = 0;
	if (!(*str >= '0' && *str <= '9'))
		ft_error();
	while (*str >= '0' && *str <= '9')
		result = result * 10 + (*str++ - '0');
	if (*str)
		ft_error();
	return (result);
}

void	send_char(int pid, unsigned char c, int last)
{
	unsigned char	mask;

	mask = 128;
	while (mask > 1)
	{
		send_bit(pid, c & mask);
		mask >>= 1;
	}
	if (last)
	{
		if (c & 1)
			kill(pid, SIGUSR2);
		else
			kill(pid, SIGUSR1);
	}
	else
		send_bit(pid, c & 1);
}

void	send_message(int pid, char *msg)
{
	int	i;

	i = 0;
	while (msg[i])
	{
		send_char(pid, (unsigned char)msg[i], 0);
		i++;
	}
	send_char(pid, 0, 1);
	write(1, "Message received.\n", 18);
}

int	main(int argc, char **argv)
{
	struct sigaction	sa;
	int					pid;

	if (argc != 3)
		ft_error();
	sa.sa_handler = ft_handler;
	sa.sa_flags = 0;
	sigemptyset(&sa.sa_mask);
	sigaddset(&sa.sa_mask, SIGUSR1);
	sigaddset(&sa.sa_mask, SIGUSR2);
	sigaction(SIGUSR1, &sa, NULL);
	sigaction(SIGUSR2, &sa, NULL);
	pid = ft_atoi_strict(argv[1]);
	connect_to_server(pid);
	wait_for_turn(pid);
	send_message(pid, argv[2]);
	return (0);
}
