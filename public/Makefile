export:
	@# see https://inkscape.org/en/doc/inkscape-man.html
	rm -f thunderbird-setup-*.png
	for i in `seq 0 5`; do \
		inkscape thunderbird-setup.svg --without-gui --export-id=step-$$i --export-png=thunderbird-setup-$$i.png -w400; \
	done
	pngquant --ext .png --force *.png

.PHONY: export