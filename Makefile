# Makefile for docker-compose
# command list
DOCKER_COMPOSE = docker compose

COMPOSE_UP = up
COMPOSE_DOWN = down
COMPOSE_STOP = stop
COMPOSE_BUILD = build

BUILD_FLAGS = --progress=plain
NO_CACHE = --no-cache
PRE_BUILD = --build

SRCS_DIR = ./srcs
COMPOSE_FILE = $(SRCS_DIR)/docker-compose.yml

COMPOSE_CMD = $(DOCKER_COMPOSE) -f $(COMPOSE_FILE)

NAME = inception

COMPILE_MSG	= @echo $(BOLD)$(L_PURPLE) 📣 $(NAME) Compiled 🥳$(RESET)

.PHONY : all
all :
	@$(COMPOSE_CMD) $(COMPOSE_UP) -d $(PRE_BUILD)

.PHONY : clean
clean :
	@$(COMPOSE_CMD) $(COMPOSE_DOWN) --remove-orphans
	@echo $(BOLD)$(L_RED) 🗑️ Removed all docker composed containers$(RESET)

.PHONY : fclean
fclean : clean
	@sudo rm -rf $(HOME)/data
	@echo $(BOLD)$(L_PURPLE) 🗑️ Removed volume data $(RESET)

.PHONY : re
re : fclean
	@make all

.PHONY : stop
stop :
	@$(COMPOSE_CMD) $(COMPOSE_STOP)

.PHONY : build
build :
	@$(COMPOSE_CMD) $(COMPOSE_BUILD) $(BUILD_FLAGS)

.PHONY : ps
ps :
	@$(COMPOSE_CMD) ps

.PHONY : exec
exec :
	@$(COMPOSE_CMD) exec $(S) /bin/sh

.PHONY : logs
logs :
	@$(COMPOSE_CMD) logs -f $(S)

.PHONY : top
top :
	@$(COMPOSE_CMD) top $(S)

######################### Color #########################
GREEN="\033[32m"
L_GREEN="\033[1;32m"
RED="\033[31m"
L_RED="\033[1;31m"
RESET="\033[0m"
BOLD="\033[1m"
L_PURPLE="\033[1;35m"
L_CYAN="\033[1;96m"
UP = "\033[A"
CUT = "\033[K"
