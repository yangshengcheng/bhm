#
# makefile for Notes API sample program STATDEMO
# Windows 32-bit version using Microsoft Visual C++ .NET compiler
# and linker.
#
# This makefile assumes that the INCLUDE and LIB environment variables
# are set up to point at the Notes and C "include" and "lib" directories.

# Standard Windows 32-bit make definitions
!include <ntwin32.mak>

cpuflags = /Zp
outfilename = ndominostat

# Update the executable file if necessary, and if so, add the resource
# back in.
$(outfilename).exe: dominostat.obj dominostat.res
	$(link) $(linkdebug) $(conflags) dominostat.obj notes0.obj notesai0.obj \
		dominostat.res $(conlibs) notes.lib user32.lib -out:$(outfilename).exe

# Update the resource file if necessary.
dominostat.res : dominostat.rc dominostat.h
        rc -r -fo dominostat.res -DWIN32 -D_WIN32 /DNT dominostat.rc

# Update the object file if necessary.
dominostat.obj : dominostat.c dominostat.h
	$(cc) $(cdebug) $(cflags) $(cpuflags) $(cvars) /DNT dominostat.c
