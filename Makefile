.SUFFIXES: .erl .beam

MODULES  = system acceptor client commander database leader replica scout server utils

# BUILD =======================================================

ERLC	= erlc -o ebin

ebin/%.beam: %.erl
	$(ERLC) $<

all:	ebin ${MODULES:%=ebin/%.beam}

ebin:
	mkdir ebin

.PHONY: clean
clean:
	rm -f ebin/* erl_crash.dump

# RUN =========================================================

SYSTEM     = system
L_ERL      = erl -noshell -pa ebin -setcookie pass

run: all
	$(L_ERL) -s $(SYSTEM) start
