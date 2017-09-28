/*  ftinstall : for cross compiling system image installations
 *  
 *  "Good old linux... how easy was this!  I thought I was going to have
 *   to write my own library loader"
 *  Copyright(C) 2017  Peter Bohning
 *  This program is free software : you can redistribute it and / or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

extern uint8_t write_redirectlib[] asm("_binary_write_redirect_so_start");
extern uint8_t write_redirectlibend[] asm("_binary_write_redirect_so_end");

int main(int argc, char ** argv)
{
	char * commandline;
	int i, size;
	int write_redirectlibsize;
	FILE * lib;
	int ret;

	if(argc < 3)
	{
		printf("ftinstall [root] [command]\n");
		return 0;
	}
	if(strlen(argv[1]) < 15)
	{
		printf("*Cough*  That's kind of a short root, isn't it...\n");
		sleep(5);
	}
	printf("Using %s as root...\n", argv[1]);
	setenv("FTINSTALL_ROOT", argv[1], 1);

	write_redirectlibsize = write_redirectlibend - write_redirectlib;
	lib = fopen("/tmp/write_redirect.so", "w");
	fwrite(write_redirectlib, sizeof(char), write_redirectlibsize, lib);
	fclose(lib);

	size = 0;
	for(i = 2; i < argc; i++)
		size += strlen(argv[i]);
	commandline = (char *)malloc(size + 40);
	sprintf(commandline, "LD_PRELOAD=/tmp/write_redirect.so ");
	for(i = 2; i < argc; i++)
		sprintf(&(commandline[strlen(commandline)]), "%s ", argv[i]);
	if(system(commandline) != 0)
	{
		ret = -1;
		printf("Command %s failed\n", commandline);
	}
	else
		ret = 0;
	sprintf(commandline, "rm /tmp/write_redirect.so");
	system(commandline);
	free(commandline);
	return ret;
}
