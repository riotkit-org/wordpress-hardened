SUDO=sudo

all: build

build:
	${SUDO} docker build . -t wolnosciowiec/wp-auto-update

