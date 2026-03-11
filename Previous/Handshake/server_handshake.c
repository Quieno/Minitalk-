#include <signal.h>
#include <unistd.h>

void	ft_putnbr(int n)
{
	char	c;

	if (n >= 10)
		ft_putnbr(n / 10);
	c = (n % 10) + '0';
	write(1, &c, 1);
}

void	handler(int signum, siginfo_t *info, void *context)
{
	static unsigned char	mask = 128;
	static unsigned char	letter = 0;

	(void)context;
	if (signum == SIGUSR2)
		letter |= mask;
	mask >>= 1;
	if (mask == 0)
	{
		if (letter != 0)
			write(1, &letter, 1);
		else
			write(1, "\n", 1);
		mask = 128;
		letter = 0;
	}
	kill(info->si_pid, SIGUSR1);
}

int	main(void)
{
	struct sigaction	siga;

	ft_putnbr(getpid());
	write(1, "\n", 1);
	siga.sa_sigaction = handler;
	siga.sa_flags = SA_SIGINFO;
	sigemptyset(&siga.sa_mask);
	sigaction(SIGUSR1, &siga, NULL);
	sigaction(SIGUSR2, &siga, NULL);
	while (1)
		pause();
	return (0);
}
