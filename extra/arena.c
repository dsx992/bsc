#include <stddef.h>
#include <stdint.h>

struct memory_region
{
    uint8_t *start;
    size_t   size;
};

struct arena_allocator
{
    struct memory_region region;
    size_t               allocated;
};

struct arena_allocator scratch_arena =
{
    .region = 
    {
        .start = (uint8_t*)0x1000,
        .size = 0x2000
    },
    allocated = 0
};


/* pseudo instruction scr.alloc[τ] rd, rs,
 * updates regfile [rd: scratch τ array(bytes)] */
void* scratch_alloc(size_t bytes)
{
    void* start = scratch_arena.region.start + scratch_arena.size;
    scratch_arena.size += bytes;

    return start;
}

/* pseudo instruction scr.alloc[τ] rd, rs, ra,
 * updates regfile [rd: scratch τ array(bytes)] */
void* alloc(struct arena_allocator arena, size_t bytes)
{
    void* start = arena.region.start + arena.size;
    arena.size += bytes;

    return start;
}


int main()
{
    scratch_arena.allocated += 16;

    return 0;
}
