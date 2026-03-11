#include <signal.h>
#include <unistd.h>

#define MAX_CLIENTS 10
#define MAX_MSG_LEN 4096

void	ft_putnbr(int n)
{
	char	c;

	if (n >= 10)
		ft_putnbr(n / 10);
	c = (n % 10) + '0';
	write(1, &c, 1);
}

int	get_slot(pid_t *pids, unsigned char *masks, pid_t pid)
{
	int	i;

	i = 0;
	while (i < MAX_CLIENTS && pids[i] != pid && pids[i] != 0)
		i++;
	if (i == MAX_CLIENTS)
		return (-1);
	if (pids[i] == 0)
	{
		pids[i] = pid;
		masks[i] = 128;
	}
	return (i);
}

void	buffer_char(int i, unsigned char letter, pid_t *pids)
{
	static char		buffers[MAX_CLIENTS][MAX_MSG_LEN];
	static int		buf_idx[MAX_CLIENTS];

	if (letter != 0 && buf_idx[i] < MAX_MSG_LEN - 1)
		buffers[i][buf_idx[i]++] = letter;
	else if (letter == 0)
	{
		buffers[i][buf_idx[i]] = '\0';
		write(1, buffers[i], buf_idx[i]);
		write(1, "\n", 1);
		buf_idx[i] = 0;
		pids[i] = 0;
	}
}

void	handler(int signum, siginfo_t *info, void *context)
{
	static pid_t			pids[MAX_CLIENTS];
	static unsigned char	masks[MAX_CLIENTS];
	static unsigned char	letters[MAX_CLIENTS];
	int						i;

	(void)context;
	i = get_slot(pids, masks, info->si_pid);
	if (i == -1)
		return ;
	if (signum == SIGUSR2)
		letters[i] |= masks[i];
	masks[i] >>= 1;
	if (masks[i] == 0)
	{
		buffer_char(i, letters[i], pids);
		masks[i] = 128;
		letters[i] = 0;
	}
	kill(info->si_pid, SIGUSR1);
}

int	main(void)
{
	struct sigaction	sa;

	ft_putnbr(getpid());
	write(1, "\n", 1);
	sa.sa_sigaction = handler;
	sa.sa_flags = SA_SIGINFO;
	sigemptyset(&sa.sa_mask);
	sigaction(SIGUSR1, &sa, NULL);
	sigaction(SIGUSR2, &sa, NULL);
	while (1)
		pause();
	return (0);
}
