NAME_SRV	= server
NAME_CLT	= client

CC			= cc
CFLAGS		= -Wall -Wextra -Werror

SRV_DIR		= src/server
CLT_DIR		= src/client

SRV_SRC		= $(SRV_DIR)/server.c $(SRV_DIR)/server_utils.c
CLT_SRC		= $(CLT_DIR)/client.c $(CLT_DIR)/client_utils.c

SRV_OBJ		= $(SRV_SRC:.c=.o)
CLT_OBJ		= $(CLT_SRC:.c=.o)

all: $(NAME_SRV) $(NAME_CLT)

$(NAME_SRV): $(SRV_OBJ)
	$(CC) $(CFLAGS) $(SRV_OBJ) -o $(NAME_SRV)

$(NAME_CLT): $(CLT_OBJ)
	$(CC) $(CFLAGS) $(CLT_OBJ) -o $(NAME_CLT)

$(SRV_DIR)/%.o: $(SRV_DIR)/%.c $(SRV_DIR)/server.h
	$(CC) $(CFLAGS) -I$(SRV_DIR) -c $< -o $@

$(CLT_DIR)/%.o: $(CLT_DIR)/%.c $(CLT_DIR)/client.h
	$(CC) $(CFLAGS) -I$(CLT_DIR) -c $< -o $@

clean:
	rm -f $(SRV_OBJ) $(CLT_OBJ)

fclean: clean
	rm -f $(NAME_SRV) $(NAME_CLT)

bonus: all

re: fclean all

.PHONY: bonus clean fclean re
