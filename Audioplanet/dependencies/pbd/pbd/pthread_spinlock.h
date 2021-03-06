/*
    Copyright (C) 1998-99 Paul Barton-Davis

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

    $Id: pthread_spinlock.h,v 1.1 2007/07/04 07:26:39 seppo Exp $
*/
#ifndef __pthread_mutex_spinlock_h__
#define __pthread_mutex_spinlock_h__

#include <pthread.h>

extern unsigned int pthread_calibrate_spinlimit ();
extern void         pthread_set_spinlimit (unsigned int spins);
extern int          pthread_mutex_spinlock (pthread_mutex_t *mp);

#endif // __pthread_mutex_spinlock_h__
