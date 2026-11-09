GHC = ghc
FLAGS = -O2 -Wall
PROG = prog

all: $(PROG)

$(PROG): main.hs Automata.hs Simulacion.hs
	$(GHC) $(FLAGS) main.hs -o $(PROG)

clean:
	rm -f *.hi *.o $(PROG)

.PHONY: all clean
