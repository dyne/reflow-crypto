install:
	./aux/pacapt install luajit lua-cjson jq
	curl https://files.dyne.org/zenroom/nightly/zenroom-linux-amd64 -O /usr/local/bin/zenroom
	@echo "Zenroom installed in /usr/local/bin"

check:
	./zencode_test.sh

clean:
	rm -f *.zen *.json