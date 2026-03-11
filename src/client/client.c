
#include "client.h"

volatile sig_atomic_t	g_state = 0;

/*	State 0: attempting to establish connection.
	State 1: connection successfully established.
	State 2: tanscription started. bit is sent, wait for ack.
	State 3: ack recieved for last sent bit.
	State 4: client waitint in queue, stay alive. */
void	ft_handler(int sig)
{
	if (g_state == 0 && sig == SIGUSR1)
		g_state = 1;
	else if ((g_state == 1 || g_state == 4) && sig == SIGUSR2)
		g_state = 2;
	else if ((g_state == 1 || g_state == 4) && sig == SIGUSR1)
		g_state = 4;
	else if (g_state == 2 && sig == SIGUSR1)
		g_state = 3;
}

int	wait_ack(void)
{
	int	i;

	i = 0;
	while (g_state == 2 && i < 500)
	{
		usleep(1000);
		i++;
	}
	return (g_state == 3);
}

void	send_bit(int pid, int bit)
{
	int	retries;

	retries = 0;
	while (1)
	{
		g_state = 2;
		if (bit)
			kill(pid, SIGUSR2);
		else
			kill(pid, SIGUSR1);
		if (wait_ack())
			return ;
		if (++retries >= 3)
			ft_error();
	}
}

void	connect_to_server(int pid)
{
	write(1, "Attempting connection...\n", 25);
	while (g_state == 0)
	{
		if (kill(pid, SIGUSR1) == -1)
			ft_error();
		usleep(500000);
	}
	write(1, "Connection established.\n", 24);
}

void	wait_for_turn(int pid)
{
	volatile sig_atomic_t	snap;
	int						ticks;

	ticks = 0;
	snap = g_state;
	while (g_state != 2)
	{
		usleep(1000);
		if (g_state != snap)
		{
			snap = g_state;
			ticks = 0;
		}
		if (++ticks < 2000)
			continue ;
		if (kill(pid, SIGUSR1) == -1)
			ft_error();
		ticks = 0;
		usleep(500000);
		if (g_state == snap)
			ft_error();
		snap = g_state;
	}
	write(1, "Sending message...\n", 19);
}
