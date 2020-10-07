//
//  kmem.h
//  Odyssey
//
//  Created by CoolStar on 5/26/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

#ifndef kmem_h
#define kmem_h

#include <stdio.h>
#import <mach/mach.h>
#import <stdbool.h>

size_t kread(uint64_t where, void *p, size_t size);

size_t kwrite(uint64_t where, const void *p, size_t size);

uint64_t kalloc(vm_size_t size);

void kfree(mach_vm_address_t address, vm_size_t size);

uint32_t rk32(uint64_t kaddr);

uint64_t rk64(uint64_t kaddr);

void wk32(uint64_t kaddr, uint32_t val);

void wk64(uint64_t kaddr, uint64_t val);

void init_kernel_memory(mach_port_t tfp0);

#endif /* kmem_h */
