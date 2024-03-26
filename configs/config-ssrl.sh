#!/bin/sh
EXTRAOPTS=
while getopts "t:s:h:p:o:b:v:l:" opt ; do
	case "$opt" in
		t)
  			TARGET=$OPTARG
			;;
		s)
			TOOLPATH=$OPTARG
			;;
		h)
			TOOLHOSTARCH=$OPTARG
			;;
		p)
			PREFIX=$OPTARG
			;;
		b)
			THEBSPS=$OPTARG
			;;
		v)
			SUBVERS=$OPTARG
			;;
		o)
			EXTRAOPTS="$EXTRAOPTS $OPTARG"
			;;
		l)
			EXTRALANGS="$EXTRALANGS,$OPTARG"
    esac
done
if [ -z "$TARGET" ] ; then TARGET=powerpc-rtems; fi
if [ -z "$TOOLPATH" ] ; then TOOLPATH=..; fi
if [ -z "$TOOLHOSTARCH" ]; then
	if  TOOLHOSTARCH=`sys 2>/dev/null` ; then true ; else
        TOOLHOSTARCH=i386_linux24
	fi
	export TOOLHOSTARCH
fi
if [ -z "$PREFIX" ] ; then
    echo 'please set PREFIX environment var (or -p option) to absolute installation prefix path'
	exit 1
fi
if [ ! -x $TOOLPATH/configure ]; then
    echo "cannot execute '$TOOLPATH/configure' maybe you have to use the"
    echo " -s option to point to the tool source directory"
	exit 1
fi

case "`basename $0`" in
	config-cross.ssrl)
		$TOOLPATH/configure --target=$TARGET --disable-nls --prefix=$PREFIX/host --exec-prefix=$PREFIX/host/$TOOLHOSTARCH --mandir=$PREFIX/doc/man --infodir=$PREFIX/doc/info $EXTRAOPTS
	;;
	config-gcc.ssrl)
#gcc4 offers only f95 -- but this needs gmp with MPFR support :-(; --> no fortran for now TS 2005/10/17
		$TOOLPATH/configure --target=$TARGET --prefix=$PREFIX/host/$TOOLHOSTARCH --exec-prefix=$PREFIX/host/$TOOLHOSTARCH --mandir=$PREFIX/doc/man --infodir=$PREFIX/doc/info --enable-languages=c,c++${EXTRALANGS} --with-gnu-as --with-gnu-ld --with-newlib --verbose --with-system-zlib --disable-nls --enable-version-specific-runtime-libs --enable-threads=rtems $EXTRAOPTS
	;;
	config-grub.ssrl)
		$TOOLPATH/configure --enable-3c509 --enable-ne --enable-wd --enable-eepro100 --enable-3c90x --enable-tulip --prefix=$PREFIX/host --exec-prefix=$PREFIX/host/$TOOLHOSTARCH --mandir=$PREFIX/doc/man --infodir=$PREFIX/doc/info $EXTRAOPTS
	;;
	config-rtems.ssrl)
#
# NOTE: the @sys dependent 'bindir' needs to be reflected in make/main.cfg
#       (PROJECT_BIN)
#
	bsps=''
	if [ -z "$THEBSPS" ] ; then
		case $TARGET in
			powerpc-rtems)
				bsps=--enable-rtemsbsp="mvme2307 svgm psim"
			;;
			i386-rtems)
				bsps=--enable-rtemsbsp="pc586"
			;;
			m68k-rtems)
				bsps=--enable-rtemsbsp="mvme167 uC5282"
			;;
			*)       bsps='';;
		esac
	else
		if [ "$THEBSPS" != "all" ] ; then
			bsps=--enable-rtemsbsp="$THEBSPS"
		fi
	fi

	BSPCFGOPTS=""
	case $TARGET in
		i386-rtems)
			BSPCFGOPTS="$BSPCFGOPTS IDE_USE_SECONDARY_INTERFACE=1"
		;;
		m68k-rtems)
			BSPCFGOPTS="$BSPCFGOPTS CD2401_IO_MODE=1"
			BSPCFGOPTS="$BSPCFGOPTS CD2401_USE_TERMIOS=1"
			BSPCFGOPTS="$BSPCFGOPTS CONSOLE_MINOR=0"
			BSPCFGOPTS="$BSPCFGOPTS PRINTK_MINOR=0"
		;;
	esac

# PACKAGE_VERSION is set by the RTEMS configure script itself
#rtemspath=/package/rtems/'${PACKAGE_VERSION}'/
		rtemspath=$PREFIX

#$rtemspath/src/rtems/configure
		$TOOLPATH/configure --target=$TARGET --enable-cxx --disable-rdbg "--prefix=$rtemspath/target/$SUBVERS/" "--exec-prefix=$rtemspath/target/$SUBVERS/$TARGET/" "--bindir=$rtemspath/host/$TOOLHOSTARCH/bin" --docdir=$rtemspath/doc --mandir=$rtemspath/doc/man --infodir=$rtemspath/doc/info --disable-itron --enable-posix "$bsps" --enable-maintainer-mode 'RTEMS_CFLAGS=-g -fno-strict-aliasing' $BSPCFGOPTS $EXTRAOPTS
	;;
	test)
		echo TEST
	;;
	*)
	echo "Unknown link name '$0'"
	exit 1
	;;
esac
