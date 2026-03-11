
#include "server.h"

t_state	g_state;

void	finish_char(unsigned char c)
{
	g_state.mask = 128;
	g_state.letter = 0;
	if (!c)
	{
		write(1, "\n", 1);
		dequeue();
		if (g_state.size > 0)
			kill(g_state.queue[0], SIGUSR2);
		return ;
	}
	g_state.has_output = 1;
	write(1, &c, 1);
	if (kill(g_state.queue[0], SIGUSR1) == -1)
	{
		dequeue();
		if (g_state.size > 0)
			kill(g_state.queue[0], SIGUSR2);
	}
}

void	process_bit(int sig)
{
	if (sig == SIGUSR2)
		g_state.letter |= g_state.mask;
	g_state.mask >>= 1;
	g_state.idle_ticks = 0;
	if (g_state.mask != 0)
	{
		if (kill(g_state.queue[0], SIGUSR1) == -1)
		{
			dequeue();
			if (g_state.size > 0)
				kill(g_state.queue[0], SIGUSR2);
		}
		return ;
	}
	finish_char(g_state.letter);
}

void	handler(int sig, siginfo_t *info, void *ctx)
{
	(void)ctx;
	if (g_state.size > 0 && info->si_pid == g_state.queue[0])
		process_bit(sig);
	else
		handle_connection(sig, info->si_pid);
}

void	check_timeout(void)
{
	usleep(100000);
	if (g_state.size == 0)
		return ;
	if (++g_state.idle_ticks < 20)
		return ;
	g_state.idle_ticks = 0;
	if (g_state.has_output || g_state.mask != 128)
		write(1, "\n", 1);
	dequeue();
	if (g_state.size > 0)
		kill(g_state.queue[0], SIGUSR2);
}

int	main(void)
{
	struct sigaction	sa;

	g_state.mask = 128;
	ft_putnbr(getpid());
	write(1, "\n", 1);
	sa.sa_sigaction = handler;
	sa.sa_flags = SA_SIGINFO;
	sigemptyset(&sa.sa_mask);
	sigaddset(&sa.sa_mask, SIGUSR1);
	sigaddset(&sa.sa_mask, SIGUSR2);
	sigaction(SIGUSR1, &sa, NULL);
	sigaction(SIGUSR2, &sa, NULL);
	while (1)
		check_timeout();
	return (0);
}
