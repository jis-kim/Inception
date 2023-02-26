# Makefile for docker-compose

# command list
COMPOSE = docker compose

UP = up
DOWN = down
STOP = stop

BUILD_FLAGS = -progress=plain
NO_CACHE = --no-cache
PRE_BUILD = --build

BUILD = docker compose $(BUILD_FLAGS)
DOCKER_COMPOSE = docker compose


NAME = inception

COMPILE_MSG	= @echo $(BOLD)$(L_PURPLE) 📣 $(NAME) Compiled 🥳$(RESET)


.PHONY : all
all :
	$(DOCKER_COMPOSE) $(UP) $(PRE_BUILD)

.PHONY : clean
clean :
	@$(DOCKER_COMPOSE) $(DOWN) --remove-orphans
	@echo $(BOLD)$(L_RED) 🗑️ Removed all docker composed files 📁$(RESET)

.PHONY : fclean
fclean : clean
	@$(DOCKER_COMPOSE) $(STOP)
	@echo $(BOLD)$(L_PURPLE) 🗑️ stopped running containers! 📚$(RESET)

.PHONY : re
re : fclean
	@make all

.PHONY : debug
debug : fclean
	@make DEBUG=1


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
