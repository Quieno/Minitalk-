
#ifndef SERVER_H
# define SERVER_H

# include <signal.h>
# include <unistd.h>
# include <stdlib.h>

# define MAX_Q      10

typedef struct s_state
{
	unsigned char	mask;
	unsigned char	letter;
	int				size;
	int				has_output;
	volatile int	idle_ticks;
	pid_t			queue[MAX_Q];
}	t_state;

extern t_state	g_state;

void	ft_putnbr(int n);
void	dequeue(void);
void	handle_connection(int sig, pid_t pid);
void	finish_char(unsigned char c);
void	process_bit(int sig);
void	handler(int sig, siginfo_t *info, void *ctx);
void	check_timeout(void);

#endif
