
#ifndef CLIENT_H
# define CLIENT_H

# include <signal.h>
# include <unistd.h>
# include <stdlib.h>

void	ft_handler(int sig);
void	ft_error(void);
int		ft_atoi_strict(char *str);
void	connect_to_server(int pid);
void	wait_for_turn(int pid);
int		wait_ack(void);
void	send_bit(int pid, int bit);
void	send_char(int pid, unsigned char c, int last);
void	send_message(int pid, char *msg);

#endif
