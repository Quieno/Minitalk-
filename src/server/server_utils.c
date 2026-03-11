
#include "server.h"

void	ft_putnbr(int n)
{
	char	c;

	if (n >= 10)
		ft_putnbr(n / 10);
	c = (n % 10) + '0';
	write(1, &c, 1);
}

void	dequeue(void)
{
	int	i;

	i = 0;
	while (i < g_state.size - 1)
	{
		g_state.queue[i] = g_state.queue[i + 1];
		i++;
	}
	g_state.queue[--g_state.size] = 0;
	g_state.mask = 128;
	g_state.letter = 0;
	g_state.idle_ticks = 0;
	g_state.has_output = 0;
}

void	handle_connection(int sig, pid_t pid)
{
	int	i;

	if (sig != SIGUSR1)
		return ;
	i = 0;
	while (i < g_state.size && g_state.queue[i] != pid)
		i++;
	if (i < g_state.size)
	{
		kill(pid, SIGUSR1);
		return ;
	}
	if (g_state.size >= MAX_Q)
	{
		kill(pid, SIGUSR2);
		return ;
	}
	g_state.queue[g_state.size++] = pid;
	kill(pid, SIGUSR1);
	if (g_state.size == 1)
		kill(pid, SIGUSR2);
}
