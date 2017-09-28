/*  ftinstall : for cross compiling system image installations
 *  
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

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

//Can screw up scripts with stdout:
#define DEBUG

extern char * program_invocation_short_name;

struct stat
{
	int placeholder;
};

#define O_WRONLY			01
#define O_RDWR				02
#define O_CREAT			00000100

//#define RTLD_LAZY		0x00001
//#define RTLD_NEXT		((void *)-1)
extern FILE * fopen(const char * pathname, const char * mode);
extern FILE * fopen64(const char * pathname, const char * mode);
typedef FILE * (* fopenPtr)(const char *, const char *);

extern int open(const char * pathname, int flags, ...);
extern int open64(const char * pathname, int flags, ...);
typedef int (* openPtr)(const char * pathname, int flags, ...);

extern int mkstemp(char * template);
typedef int (* mkstempPtr)(char * template);

extern int _IO_file_fopen(void * fp, const char * pathname, const char * mode, int is32not64);
typedef int (* _IO_file_fopenPtr)(void * fp, const char * pathname, const char * mode, int is32not64);
extern int _IO_file_open(void * fp, const char * pathname, int posix_mode, int prot, int read_write, int is32not64);
typedef int (* _IO_file_openPtr)(void * fp, const char * pathname, int posix_mode, int prot, int read_write, int is32not64);

extern int chmod(const char * pathname, mode_t mode);
typedef int (* chmodPtr)(const char * pathname, mode_t mode);

extern int fchmodat(int dirfd, const char * pathname, mode_t mode, int flags);
typedef int (* fchmodatPtr)(int dirfd, const char * pathname, mode_t mode, int flags);

/* stat, lstat are inlined to: */
extern int __lxstat(int __ver, const char * pathname, struct stat * buf);
extern int __xstat(int __ver, const char * pathname, struct stat * buf);
typedef int (* statPtr)(int __ver, const char * pathname, struct stat * buf);

/* Possibly we should remove below, the fstat and the chgrp because you have to be root
 * and that's dangerous here... so we can just do it later and patch whatever */
//extern int newfstatat(int dirfd, const char * pathname, struct stat * buf, int flags);
extern int __fxstatat(int ver, int dirfd, const char * pathname, struct stat * buf, int flags);
typedef int (* fstatatPtr)(int ver, int dirfd, const char * pathname, struct stat * buf, int flags);

extern int fchownat(int dirfd, const char * pathname, uid_t owner, gid_t group, int flags);
typedef int (* fchownatPtr)(int dirfd, const char * pathname, uid_t owner, gid_t group, int flags);

/* ln are a question mark... we'll make them work for now to prevent errors
 * but they have to fixed up before the img is made */

extern int rename(const char * oldpath, const char * newpath);
typedef int (* renamePtr)(const char * oldpath, const char * newpath);

extern int link(const char * oldpath, const char * newpath);
typedef int (* linkPtr)(const char * oldpath, const char * newpath);
extern int linkat(int olddirfd, const char * oldpath, int newdirfd, const char * newpath, int flags);
typedef int (* linkatPtr)(int olddirfd, const char * oldpath, int newdirfd, const char * newpath, int flags);

extern int symlink(const char * target, const char * linkpath);
typedef int (* symlinkPtr)(const char * oldpath, const char * newpath);

extern int unlink(const char * pathname);
typedef int (* unlinkPtr)(const char * pathname);
extern int unlinkat(int dirfd, const char * pathname, int flags);
typedef int (* unlinkatPtr)(int dirfd, const char * pathname, int flags);

extern int mkdir(const char * pathname, mode_t mode);
typedef int (* mkdirPtr)(const char * pathname, mode_t mode);
extern int mkdirat(int dirfd, const char * pathname, mode_t mode);
typedef int (* mkdiratPtr)(int dirfd, const char * pathname, mode_t mode);

extern int chdir(const char * path);
typedef int (* chdirPtr)(const char * path);

extern char * getcwd(char * buf, size_t size);
typedef char * (* getcwdPtr)(char * buf, size_t size);

/*extern void * dlopen(const char * filename, int flags);

extern void *dlsym(void * handle, const char * symbol);
typedef void * (* dlsymPtr)(void * handle, const char * symbol);
extern void *dlvsym(void * handle, const char * symbol, char * version);
typedef void * (* dlvsymPtr)(void * handle, const char * symbol, char * version);
*/

FILE * fopen (const char * pathname, const char * mode)
{
	fopenPtr realfopen;
	char * newpath;
	FILE * fp;
	char * newroot;

	realfopen = dlsym(RTLD_NEXT, "fopen");
	//if(strcmp(mode, "w") == 0)
	if(1)
	{
		newroot = getenv("FTINSTALL_ROOT");
		if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
			strncmp("/dev/tty", pathname, 8) == 0 || 
			strncmp("/dev/pts", pathname, 8) == 0 || 
			strncmp("/tmp", pathname, 4) == 0 ||
			strncmp("/dev/null", pathname, 9) == 0)
			return realfopen(pathname, mode);
		newpath = malloc(strlen(pathname) + 200); 
		sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
		fprintf(stderr, "NEWPATH fopen: %s\n", newpath);
#endif //DEBUG
		fp = realfopen(newpath, mode);
		free(newpath);
		return fp;
	}
	return realfopen(pathname, mode);
}

FILE * fopen64(const char * pathname, const char * mode)
{
	fopenPtr realfopen;
	char * newpath;
	FILE * fp;
	char * newroot;

	realfopen = dlsym(RTLD_NEXT, "fopen64");
	//if(strcmp(mode, "w") == 0)
	if(1)
	{
		newroot = getenv("FTINSTALL_ROOT");
		if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
			strncmp("/dev/tty", pathname, 8) == 0 || 
			strncmp("/dev/pts", pathname, 8) == 0 || 
			strncmp("/tmp", pathname, 4) == 0 ||
			strncmp("/dev/null", pathname, 9) == 0)
			return realfopen(pathname, mode);
		newpath = malloc(strlen(pathname) + 200); 
		sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
		fprintf(stderr, "NEWPATH fopen64: %s\n", newpath);
#endif //DEBUG
		fp = realfopen(newpath, mode);
		free(newpath);
		return fp;
	}
	return realfopen(pathname, mode);
}

int open(const char * pathname, int flags, ...)
{
	openPtr realopen;
	char * newpath;
	int fd;
	char * newroot;
	mode_t mode;
	va_list args;

	if(flags & O_CREAT)
	{
		va_start(args, flags);
		mode = va_arg(args, int);
		va_end(args);
	}

	realopen = dlsym(RTLD_NEXT, "open");
	//if((flags & O_WRONLY) || (flags & O_RDWR)) 
	if(1)
	{
#ifdef DEBUG
		fprintf(stderr, "open called from %s on %s\n", program_invocation_short_name, pathname);
#endif //DEBUG
		newroot = getenv("FTINSTALL_ROOT");
		if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
			strncmp("/dev/tty", pathname, 8) == 0 || 
			strncmp("/dev/pts", pathname, 8) == 0 ||
			strncmp("/tmp", pathname, 4) == 0 ||
			strcmp("/bin/egrep", pathname) == 0 ||	// makefile calls /bin/sh opens this...
			strcmp("/dev/random", pathname) == 0 ||
			strcmp("/dev/urandom", pathname) == 0 ||
			strncmp("/dev/null", pathname, 9) == 0)
			return realopen(pathname, flags, mode);
		if(strcmp("perl", program_invocation_short_name) == 0 && (
			strncmp(&(pathname[strlen(pathname) - 3]), ".pm", 3) == 0 ||
			strncmp(&(pathname[strlen(pathname) - 3]), ".pl", 3) == 0 ||
			strncmp(&(pathname[strlen(pathname) - 8]), "makeinfo", 8) == 0))
			return realopen(pathname, flags, mode);
		newpath = malloc(strlen(pathname) + 200); 
		sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
		fprintf(stderr, "NEWPATH open: %s\n", newpath);
#endif //DEBUG
		fd = realopen(newpath, flags, mode);
		free(newpath);
		return fd;

	}
	return realopen(pathname, flags, mode);
}

int open64(const char * pathname, int flags, ...)
{
	openPtr realopen;
	char * newpath;
	int fd;
	char * newroot;
	mode_t mode;
	va_list args;

	if(flags & O_CREAT)
	{
		va_start(args, flags);
		mode = va_arg(args, int);
		va_end(args);
	}

	realopen = dlsym(RTLD_NEXT, "open64");
	//if((flags & O_WRONLY) || (flags & O_RDWR)) 
	if(1)
	{
#ifdef DEBUG
		fprintf(stderr, "open64 called from %s on %s\n", program_invocation_short_name, pathname);
#endif //DEBUG
		newroot = getenv("FTINSTALL_ROOT");
		if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
			strncmp("/dev/tty", pathname, 8) == 0 || 
			strncmp("/dev/pts", pathname, 8) == 0 ||
			strncmp("/tmp", pathname, 4) == 0 ||
			//strcmp("/bin/egrep", pathname) == 0 ||	//sigh
			strcmp("/dev/random", pathname) == 0 ||
			strcmp("/dev/urandom", pathname) == 0 ||
			strncmp("/dev/null", pathname, 9) == 0)
			return realopen(pathname, flags, mode);
		if(strcmp("perl", program_invocation_short_name) == 0 && (
			strncmp(&(pathname[strlen(pathname) - 3]), ".pm", 3) == 0 ||
			strncmp(&(pathname[strlen(pathname) - 3]), ".pl", 3) == 0 ||
			strncmp(&(pathname[strlen(pathname) - 8]), "makeinfo", 8) == 0))
			return realopen(pathname, flags, mode);
		newpath = malloc(strlen(pathname) + 200); 
		sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
		fprintf(stderr, "NEWPATH open64: %s\n", newpath);
#endif //DEBUG
		fd = realopen(newpath, flags, mode);
		free(newpath);
		return fd;

	}
	return realopen(pathname, flags, mode);
}

int _IO_file_fopen(void * fp, const char * pathname, const char * mode, int is32not64)
{
	_IO_file_fopenPtr realopen;
	char * newpath;
	int fd;
	char * newroot;

	realopen = dlsym(RTLD_NEXT, "_IO_file_fopen");
	//if((flags & O_WRONLY) || (flags & O_RDWR)) 
	if(1)
	{
#ifdef DEBUG
		fprintf(stderr, "_IO_file_fopen called from %s on %s\n", program_invocation_short_name, pathname);
#endif //DEBUG
		newroot = getenv("FTINSTALL_ROOT");
		if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
			strncmp("/dev/tty", pathname, 8) == 0 || 
			strncmp("/dev/pts", pathname, 8) == 0 ||
			strncmp("/tmp", pathname, 4) == 0 ||
			strcmp("/bin/egrep", pathname) == 0 ||	//sigh
			strncmp("/dev/null", pathname, 9) == 0)
			return realopen(fp, pathname, mode, is32not64);
		newpath = malloc(strlen(pathname) + 200); 
		sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
		fprintf(stderr, "NEWPATH open: %s\n", newpath);
#endif //DEBUG
		fd = realopen(fp, newpath, mode, is32not64);
		free(newpath);
		return fd;
	}
	return realopen(fp, pathname, mode, is32not64);
}



int _IO_file_open(void * fp, const char * pathname, int posix_mode, int prot, int read_write, int is32not64)
{
	_IO_file_openPtr realopen;
	char * newpath;
	int fd;
	char * newroot;

	realopen = dlsym(RTLD_NEXT, "_IO_file_open");
	//if((flags & O_WRONLY) || (flags & O_RDWR)) 
	if(1)
	{
#ifdef DEBUG
		fprintf(stderr, "_IO_file_open called from %s on %s\n", program_invocation_short_name, pathname);
#endif //DEBUG
		newroot = getenv("FTINSTALL_ROOT");
		if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
			strncmp("/dev/tty", pathname, 8) == 0 || 
			strncmp("/dev/pts", pathname, 8) == 0 ||
			strncmp("/tmp", pathname, 4) == 0 ||
			strcmp("/bin/egrep", pathname) == 0 ||	//sigh
			strncmp("/dev/null", pathname, 9) == 0)
			return realopen(fp, pathname, posix_mode, prot, read_write, is32not64);
		newpath = malloc(strlen(pathname) + 200); 
		sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
		fprintf(stderr, "NEWPATH open: %s\n", newpath);
#endif //DEBUG
		fd = realopen(fp, newpath, posix_mode, prot, read_write, is32not64);
		free(newpath);
		return fd;
	}
	return realopen(fp, pathname, posix_mode, prot, read_write, is32not64);
}

int mkstemp(char * template)
{
	mkstempPtr realmkstemp;
	char * newpath;
	int fd;
	char * newroot;

	realmkstemp = dlsym(RTLD_NEXT, "mkstemp");
#ifdef DEBUG
	fprintf(stderr, "mkstemp called from %s on %s\n", program_invocation_short_name, template);
#endif //DEBUG
	newroot = getenv("FTINSTALL_ROOT");
	if(template[0] != '/' || strncmp(newroot, template, 15) == 0 ||
		strncmp("/dev/tty", template, 8) == 0 || 
		strncmp("/dev/pts", template, 8) == 0 ||
		strncmp("/tmp", template, 4) == 0 ||
		strncmp("/dev/null", template, 9) == 0)
		return realmkstemp(template);
	newpath = malloc(strlen(template) + 200); 
	sprintf(newpath, "%s%s", newroot, template);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH mkstemp: %s\n", newpath);
#endif //DEBUG
	fd = realmkstemp(newpath);
	free(newpath);
	return fd;
}

int chmod(const char * pathname, mode_t mode)
{
	chmodPtr realchmod;
	char * newpath;
	char * newroot;
	int ret;

	realchmod = dlsym(RTLD_NEXT, "chmod");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0)
		return realchmod(pathname, mode);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH chmod: %s\n", newpath);
#endif //DEBUG
	ret = realchmod(newpath, mode);
	free(newpath);
	return ret;
}

int fchmodat(int dirfd, const char * pathname, mode_t mode, int flags)
{
	fchmodatPtr realfchmodat;
	char * newpath;
	char * newroot;
	int ret;

	realfchmodat = dlsym(RTLD_NEXT, "fchmodat");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0)
		return realfchmodat(dirfd, pathname, mode, flags);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH fchmodat: %s\n", newpath);
#endif //DEBUG
	ret = realfchmodat(dirfd, newpath, mode, flags);
	free(newpath);
	return ret;
}

int __lxstat(int __ver, const char * pathname, struct stat * buf)
{
	statPtr real__lxstat;
	char * newpath;
	char * newroot;
	int ret;

	real__lxstat = dlsym(RTLD_NEXT, "__lxstat");
#ifdef DEBUG
	fprintf(stderr, "lxstat called from %s on %s\n", program_invocation_short_name, pathname);
#endif //DEBUG
	if(strcmp(program_invocation_short_name, "mv") != 0 &&
		strcmp(program_invocation_short_name, "rm") != 0 &&
		strcmp(program_invocation_short_name, "cp") != 0 &&
		strcmp(program_invocation_short_name, "mkdir") != 0 &&
		strcmp(program_invocation_short_name, "chmod") != 0 &&
		strcmp(program_invocation_short_name, "make") != 0 &&
		strcmp(program_invocation_short_name, "makeinfo") != 0 &&
		strcmp(program_invocation_short_name, "sh") != 0 &&
		strcmp(program_invocation_short_name, "bash") != 0 &&
		strcmp(program_invocation_short_name, "gawk") != 0 &&
		//strcmp(program_invocation_short_name, "grep") != 0 &&
		//strcmp(program_invocation_short_name, "egrep") != 0 &&
		//strcmp(program_invocation_short_name, "fgrep") != 0 &&
		strcmp(&(program_invocation_short_name[strlen(program_invocation_short_name) - 5]), "strip") != 0 &&
		strcmp(&(program_invocation_short_name[strlen(program_invocation_short_name) - 6]), "ranlib") != 0 &&
		strcmp(program_invocation_short_name, "install") != 0 &&
		strcmp(program_invocation_short_name, "ln") != 0)
		return real__lxstat(__ver, pathname, buf);
	if((strcmp(program_invocation_short_name, "bash") == 0 || strcmp(program_invocation_short_name, "sh") == 0) && /*(strncmp("/bin", pathname, 4) == 0 || strncmp("/usr/bin", pathname, 8) == 0)*/ strncmp("/share", pathname, 6) != 0)
		return real__lxstat(__ver, pathname, buf);
	if(strncmp(pathname, "/tmp", 4) == 0)
		return real__lxstat(__ver, pathname, buf);
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0)
		return real__lxstat(__ver, pathname, buf);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH lxstat: %s\n", newpath);
#endif //DEBUG
	ret = real__lxstat(__ver, newpath, buf);
	free(newpath);
	return ret;
}

int __xstat(int __ver, const char * pathname, struct stat * buf)
{
	statPtr real__xstat;
	char * newpath;
	char * newroot;
	int ret;

	real__xstat = dlsym(RTLD_NEXT, "__xstat");
#ifdef DEBUG
	fprintf(stderr, "xstat called from %s on %s\n", program_invocation_short_name, pathname);
#endif //DEBUG
	if(strcmp(program_invocation_short_name, "mv") != 0 &&
		strcmp(program_invocation_short_name, "rm") != 0 &&
		strcmp(program_invocation_short_name, "cp") != 0 &&
		strcmp(program_invocation_short_name, "mkdir") != 0 &&
		strcmp(program_invocation_short_name, "chmod") != 0 &&
		strcmp(program_invocation_short_name, "make") != 0 &&
		strcmp(program_invocation_short_name, "makeinfo") != 0 &&
		strcmp(program_invocation_short_name, "sh") != 0 &&
		strcmp(program_invocation_short_name, "bash") != 0 &&
		strcmp(program_invocation_short_name, "gawk") != 0 &&
		//strcmp(program_invocation_short_name, "grep") != 0 &&
		//strcmp(program_invocation_short_name, "egrep") != 0 &&
		//strcmp(program_invocation_short_name, "fgrep") != 0 &&
		strcmp(&(program_invocation_short_name[strlen(program_invocation_short_name) - 5]), "strip") != 0 &&
		strcmp(&(program_invocation_short_name[strlen(program_invocation_short_name) - 6]), "ranlib") != 0 &&
		strcmp(program_invocation_short_name, "install") != 0 &&
		strcmp(program_invocation_short_name, "ln") != 0)
		return real__xstat(__ver, pathname, buf);
	if(strcmp(program_invocation_short_name, "bash") == 0 || strcmp(program_invocation_short_name, "sh") == 0) 
	{
		if(strncmp(&(pathname[strlen(pathname) - 4]), "/sed", 4) == 0 ||
			strncmp(&(pathname[strlen(pathname) - 4]), "/make", 4) == 0)
			return real__xstat(__ver, pathname, buf);
		if(strncmp("/share", pathname, 6) != 0 &&
			strncmp("/lib", pathname, 4) != 0)
			return real__xstat(__ver, pathname, buf);
	}
	if(strncmp(pathname, "/tmp", 4) == 0)
		return real__xstat(__ver, pathname, buf);
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0)
		return real__xstat(__ver, pathname, buf);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH xstat: %s\n", newpath);
#endif //DEBUG
	ret = real__xstat(__ver, newpath, buf);
	free(newpath);
	return ret;
}


/*int fstatat64(int dirfd, const char * pathname, struct stat * buf, int flags)
{
	fstatatPtr realfstatat;
	char * newpath;
	char * newroot;
	int ret;

	realfstatat = dlsym(RTLD_NEXT, "fstatat64");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
		strncmp("/dev/tty", pathname, 8) == 0 || 
		strncmp("/dev/pts", pathname, 8) == 0 || 
		strncmp("/tmp", pathname, 4) == 0 ||
		strncmp("/dev/null", pathname, 9) == 0)
		return realfstatat(dirfd, pathname, buf, flags);

	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH newfstatat: %s\n", newpath);
#endif //DEBUG
	ret = realfstatat(dirfd, newpath, buf, flags);
	free(newpath);
	return ret;
}*/

int __fxstatat(int ver, int dirfd, const char * pathname, struct stat * buf, int flags)
{
	fstatatPtr realfstatat;
	char * newpath;
	char * newroot;
	int ret;

	realfstatat = dlsym(RTLD_NEXT, "__fxstatat");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
		strncmp("/dev/tty", pathname, 8) == 0 || 
		strncmp("/dev/pts", pathname, 8) == 0 || 
		strncmp("/tmp", pathname, 4) == 0 ||
		strncmp("/dev/null", pathname, 9) == 0)
		return realfstatat(ver, dirfd, pathname, buf, flags);

	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH fstatat: %s\n", newpath);
#endif //DEBUG
	ret = realfstatat(ver, dirfd, newpath, buf, flags);
	free(newpath);
	return ret;
}

int fchownat(int dirfd, const char * pathname, uid_t owner, gid_t group, int flags)
{
	fchownatPtr realfchownat;
	char * newpath;
	char * newroot;
	int ret;

	realfchownat = dlsym(RTLD_NEXT, "fchownat");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 ||
		strncmp("/dev/tty", pathname, 8) == 0 || 
		strncmp("/dev/pts", pathname, 8) == 0 || 
		strncmp("/tmp", pathname, 4) == 0 ||
		strncmp("/dev/null", pathname, 9) == 0)
		return realfchownat(dirfd, pathname, owner, group, flags);

	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH fchownat: %s\n", newpath);
#endif //DEBUG
	ret = realfchownat(dirfd, newpath, owner, group, flags);
	free(newpath);
	return ret;
}

int rename(const char * oldpath, const char * newpath)
{
	renamePtr realrename;
	char * newoldpath, * newnewpath;
	char * newroot;
	int ret;

	realrename = dlsym(RTLD_NEXT, "rename");
	newroot = getenv("FTINSTALL_ROOT");
	if(oldpath[0] != '/' || strncmp(newroot, oldpath, 15) == 0 || strncmp(oldpath, "/tmp", 4) == 0)
		newoldpath = 0;
	else
	{
		newoldpath = malloc(strlen(oldpath) + 200); 
		sprintf(newoldpath, "%s%s", newroot, oldpath);
#ifdef DEBUG
		fprintf(stderr, "NEWOLDPATH: %s\n", newoldpath);
#endif //DEBUG
	}
	if(newpath[0] != '/' || strncmp(newroot, newpath, 15) == 0 || strncmp(newpath, "/tmp", 4) == 0)
		newnewpath = 0;
	else
	{
		newnewpath = malloc(strlen(newpath) + 200); 
		sprintf(newnewpath, "%s%s", newroot, newpath);
#ifdef DEBUG
		fprintf(stderr, "NEWNEWPATH: %s\n", newnewpath);
#endif //DEBUG
	}
	
	if(!newoldpath)
	{
		if(!newnewpath)
			return realrename(oldpath, newpath);
		else
			ret = realrename(oldpath, newnewpath);
		free(newnewpath);
		return ret;
	}
	else
	{
		if(!newnewpath)
		{
			//seriously?  why would this ever happen...
			ret = realrename(newoldpath, newpath);
			free(newoldpath);
			return ret;
		}
		ret = realrename(newoldpath, newnewpath);
		free(newoldpath);
		free(newnewpath);
		return ret;
	}
}

int link(const char * oldpath, const char * newpath)
{
	linkPtr reallink;
	char * newoldpath, * newnewpath;
	char * newroot;
	int ret;

	reallink = dlsym(RTLD_NEXT, "link");
	newroot = getenv("FTINSTALL_ROOT");
	if(oldpath[0] != '/' || strncmp(newroot, oldpath, 15) == 0 || strncmp(oldpath, "/tmp", 4) == 0)
		newoldpath = 0;
	else
	{
		newoldpath = malloc(strlen(oldpath) + 200); 
		sprintf(newoldpath, "%s%s", newroot, oldpath);
#ifdef DEBUG
		fprintf(stderr, "NEWOLDPATH: %s\n", newoldpath);
#endif //DEBUG
	}
	if(newpath[0] != '/' || strncmp(newroot, newpath, 15) == 0 || strncmp(newpath, "/tmp", 4) == 0)
		newnewpath = 0;
	else
	{
		newnewpath = malloc(strlen(newpath) + 200); 
		sprintf(newnewpath, "%s%s", newroot, newpath);
#ifdef DEBUG
		fprintf(stderr, "NEWNEWPATH: %s\n", newnewpath);
#endif //DEBUG
	}
	
	if(!newoldpath)
	{
		if(!newnewpath)
			return reallink(oldpath, newpath);
		else
			ret = reallink(oldpath, newnewpath);
		free(newnewpath);
		return ret;
	}
	else
	{
		if(!newnewpath)
		{
			ret = reallink(newoldpath, newpath);
			free(newoldpath);
			return ret;
		}
		ret = reallink(newoldpath, newnewpath);
		free(newoldpath);
		free(newnewpath);
		return ret;
	}
}

int linkat(int olddirfd, const char * oldpath, int newdirfd, const char * newpath, int flags)
{
	linkatPtr reallinkat;
	char * newoldpath, * newnewpath;
	char * newroot;
	int ret;

	reallinkat = dlsym(RTLD_NEXT, "linkat");
	newroot = getenv("FTINSTALL_ROOT");
	if(oldpath[0] != '/' || strncmp(newroot, oldpath, 15) == 0 || strncmp(oldpath, "/tmp", 4) == 0)
		newoldpath = 0;
	else
	{
		newoldpath = malloc(strlen(oldpath) + 200); 
		sprintf(newoldpath, "%s%s", newroot, oldpath);
#ifdef DEBUG
		fprintf(stderr, "NEWOLDPATH: %s\n", newoldpath);
#endif //DEBUG
	}
	if(newpath[0] != '/' || strncmp(newroot, newpath, 15) == 0 || strncmp(newpath, "/tmp", 4) == 0)
		newnewpath = 0;
	else
	{
		newnewpath = malloc(strlen(newpath) + 200); 
		sprintf(newnewpath, "%s%s", newroot, newpath);
#ifdef DEBUG
		fprintf(stderr, "NEWNEWPATH: %s\n", newnewpath);
#endif //DEBUG
	}
	
	if(!newoldpath)
	{
		if(!newnewpath)
			return reallinkat(olddirfd, oldpath, newdirfd, newpath, flags);
		else
			ret = reallinkat(olddirfd, oldpath, newdirfd, newnewpath, flags);
		free(newnewpath);
		return ret;
	}
	else
	{
		if(!newnewpath)
		{
			ret = reallinkat(olddirfd, newoldpath, newdirfd, newpath, flags);
			free(newoldpath);
			return ret;
		}
		ret = reallinkat(olddirfd, newoldpath, newdirfd, newnewpath, flags);
		free(newoldpath);
		free(newnewpath);
		return ret;
	}
}

/* This one is a little silly.  We'd pretty much never want to
 * link anything that was outside of the root... but... */
int symlink(const char * target, const char * linkpath)
{
	symlinkPtr realsymlink;
	char * newtarget, * newlinkpath;
	char * newroot;
	int ret;

	realsymlink = dlsym(RTLD_NEXT, "symlink");
	newroot = getenv("FTINSTALL_ROOT");
	if(target[0] != '/' || strncmp(newroot, target, 15) == 0)
		newtarget = 0;
	else
	{
		newtarget = malloc(strlen(target) + 200); 
		sprintf(newtarget, "%s%s", newroot, target);
#ifdef DEBUG
		fprintf(stderr, "NEWTARGET: %s\n", newtarget);
#endif //DEBUG
	}
	if(linkpath[0] != '/' || strncmp(newroot, linkpath, 15) == 0)
		newlinkpath = 0;
	else
	{
		newlinkpath = malloc(strlen(linkpath) + 200); 
		sprintf(newlinkpath, "%s%s", newroot, linkpath);
#ifdef DEBUG
		fprintf(stderr, "NEWNEWPATH: %s\n", newlinkpath);
#endif //DEBUG
	}
	
	if(!newtarget)
	{
		if(!newlinkpath)
			return realsymlink(target, linkpath);
		else
			ret = realsymlink(target, newlinkpath);
		free(newlinkpath);
		return ret;
	}
	else
	{
		if(!newlinkpath)
		{
			ret = realsymlink(newtarget, linkpath);
			free(newtarget);
			return ret;
		}
		ret = realsymlink(newtarget, newlinkpath);
		free(newtarget);
		free(newlinkpath);
		return ret;
	}
}

int unlink(const char * pathname)
{
	unlinkPtr realunlink;
	char * newpath;
	char * newroot;
	int ret;

	realunlink = dlsym(RTLD_NEXT, "unlink");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 || strncmp(pathname, "/tmp", 4) == 0)
		return realunlink(pathname);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH: %s\n", newpath);
#endif //DEBUG
	ret = realunlink(newpath);
	free(newpath);
	return ret;
}

int unlinkat(int dirfd, const char * pathname, int flags)
{
	unlinkatPtr realunlinkat;
	char * newpath;
	char * newroot;
	int ret;

	realunlinkat = dlsym(RTLD_NEXT, "unlinkat");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0 || strncmp(pathname, "/tmp", 4) == 0)
		return realunlinkat(dirfd, pathname, flags);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH: %s\n", newpath);
#endif //DEBUG
	ret = realunlinkat(dirfd, newpath, flags);
	free(newpath);
	return ret;
}

int mkdir(const char * pathname, mode_t mode)
{
	mkdirPtr realmkdir;
	char * newpath;
	char * newroot;
	int ret;

	realmkdir = dlsym(RTLD_NEXT, "mkdir");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0)
		return realmkdir(pathname, mode);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH: %s\n", newpath);
#endif //DEBUG
	ret = realmkdir(newpath, mode);
	free(newpath);
	return ret;
}

int mkdirat(int dirfd, const char * pathname, mode_t mode)
{
	mkdiratPtr realmkdirat;
	char * newpath;
	char * newroot;
	int ret;

	realmkdirat = dlsym(RTLD_NEXT, "mkdirat");
	newroot = getenv("FTINSTALL_ROOT");
	if(pathname[0] != '/' || strncmp(newroot, pathname, 15) == 0)
		return realmkdirat(dirfd, pathname, mode);
	newpath = malloc(strlen(pathname) + 200); 
	sprintf(newpath, "%s%s", newroot, pathname);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH: %s\n", newpath);
#endif //DEBUG
	ret = realmkdirat(dirfd, newpath, mode);
	free(newpath);
	return ret;
}

int chdir(const char * path)
{
	chdirPtr realchdir;
	char * newpath;
	char * newroot;
	int ret;

	realchdir = dlsym(RTLD_NEXT, "chdir");
	newroot = getenv("FTINSTALL_ROOT");
	if(path[0] != '/' || strncmp(newroot, path, 15) == 0)
		return realchdir(path);
	newpath = malloc(strlen(path) + 200); 
	sprintf(newpath, "%s%s", newroot, path);
#ifdef DEBUG
	fprintf(stderr, "NEWPATH: %s\n", newpath);
#endif //DEBUG
	ret = realchdir(newpath);
	free(newpath);
	return ret;
}

char * getcwd(char * buf, size_t size)
{
	getcwdPtr realgetcwd;
	char * newroot;
	char * actualwd;
	int i;
	int n;
	int l;

	realgetcwd = dlsym(RTLD_NEXT, "getcwd");
	actualwd = realgetcwd(buf, size);
	if(!actualwd)
		return NULL;
	newroot = getenv("FTINSTALL_ROOT");
	n = strlen(newroot);
	if(strncmp(actualwd, newroot, n) == 0)
	{
		l = strlen(actualwd) - n;
		for(i = 0; i < l; i++)
			actualwd[i] = actualwd[i + n];
		actualwd[i] = 0x00;
#ifdef DEBUG
		fprintf(stderr, "NEWPATH: %s\n", actualwd);
#endif //DEBUG
	}
	return actualwd;
}

/*
extern void *_dl_sym(void * handle, const char * symbol);

void *dlsym(void * handle, const char * symbol)
{
	dlsymPtr realdlsym;
	void * libdl_handle;

	libdl_handle = dlopen("libdl.so", RTLD_LAZY);
	realdlsym = _dl_sym(libdl_handle, "dlsym");
	fprintf(stderr, "%s called dlsym on %s\n", program_invocation_short_name, symbol);
	return realdlsym(handle, symbol); 
}

void *dlvsym(void * handle, const char * symbol, char * version)
{
	dlvsymPtr realdlvsym;
	void * libdl_handle;

	libdl_handle = dlopen("libdl.so", RTLD_LAZY);
	realdlvsym = _dl_sym(libdl_handle, "dlvsym");
	fprintf(stderr, "%s called dlvsym\n", program_invocation_short_name);
	return realdlvsym(handle, symbol, version); 
}
*/
