@echo off
py -3 NtS1LevelConvert.py levels
ca65 src/nova.s -o src/nova.o -l nova.lst -g
ld65 -C src/nova.x src/nova.o -o nova.nes -m map.txt --dbgfile debug.dbg
pause
