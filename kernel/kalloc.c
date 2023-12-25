// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.
int reference_count[PHYSTOP >> 12];//引用次数 记录某块物理内存引用计数
struct spinlock ref_cnt_lock;

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()//初始化引用计数的锁
{
  initlock(&kmem.lock, "kmem");
  initlock(&ref_cnt_lock, "ref_cnt");
  freerange(end, (void*)PHYSTOP);
}


////初始化引用计数
void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
  {
    reference_count[(uint64)p >> 12] = 1;
    kfree(p);
  }
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)

////引用计数为0时才释放物理内存
void
kfree(void *pa)
{
  struct run *r;
  int tmp, pn;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  acquire(&ref_cnt_lock);
  pn = (uint64) pa >> 12;
  if (reference_count[pn] < 1)
    panic("kfree ref");
  reference_count[pn] -= 1;
  tmp = reference_count[pn];
  release(&ref_cnt_lock);

  if (tmp > 0) return;
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.


////分配物理内存时初始化引用计数为1
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r) {
    kmem.freelist = r->next;
    acquire(&ref_cnt_lock);
    reference_count[(uint64)r>>12] = 1; // first allocate, reference = 1
    release(&ref_cnt_lock);
  }
  release(&kmem.lock);

  if(r)  memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
