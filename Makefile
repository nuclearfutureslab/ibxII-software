
all:
	ca65 -t apple2 ibxII128.s -o ibxII128.o
	ld65 -o ibxII128.bin ibxII128.o -C apple2.cfg
	echo '10 PRINT CHR$$(4)"BRUN IBXII"' > loader.txt
	cp cc65.dsk ibxII128.dsk
	tokenize_asoft <loader.txt > ibxII128_loader
	dos33 ibxII128.dsk SAVE A ibxII128_loader HELLO
	java -jar ../ac.jar -cc65 ibxII128.dsk IBXII B < ibxII128.bin

clean:
	rm -f ibxII128.o ibxII128.bin ibxII128.dsk ibxII128_loader

