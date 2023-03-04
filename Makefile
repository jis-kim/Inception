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

NAME = inception

COMPILE_MSG	= @echo $(BOLD)$(L_PURPLE) 📣 $(NAME) Compiled 🥳$(RESET)


.PHONY : all
all :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) $(COMPOSE_UP) -d $(PRE_BUILD)

.PHONY : clean
clean :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) $(COMPOSE_DOWN) --remove-orphans
	@sudo rm -rf $(HOME)/data
	@echo $(BOLD)$(L_RED) 🗑️ Removed all docker composed containers$(RESET)

.PHONY : fclean
fclean : clean
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) $(COMPOSE_STOP)
	@echo $(BOLD)$(L_PURPLE) 🗑️ stopped running containers! 📚$(RESET)

.PHONY : re
re : fclean
	@make all

build :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) $(COMPOSE_BUILD) $(BUILD_FLAGS)

.PHONY : ps
ps :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) ps

exec :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) exec $(S) /bin/sh

logs :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs $(S)

top :
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) top $(S)

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
