#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>

#include "lulesh.h"

Pair *pair;
int pair_size = 0;
pthread_mutex_t creation_lock;

void signal_handler(int sig){
}

void *doing_compression(void *)
{
	signal(SIGUSR1, signal_handler);
	int rank;
	MPI_Comm_rank( MPI_COMM_WORLD, &rank );

	while(1){

		if( send_locks == NULL )
			continue;

		//pthread_mutex_lock( &(send_locks[rank]) );
		pthread_mutex_lock( &creation_lock );
		pthread_mutex_unlock( &creation_lock );
		for( int i = pair_size-1; i > 0; i-- ){
			pthread_mutex_lock( &(send_locks[rank]) );
			pthread_mutex_lock( &creation_lock );

			if( pair[i].isend_addr != NULL && pair[i].isend_size > 1000 ){
				pair[i].comp_size = compress_lz4_buffer( pair[i].isend_addr, pair[i].isend_size,
				                         		 pair[i].comp_addr, pair[i].isend_size + 100 );
				pair[i].ready = 1;
			}

			pthread_mutex_unlock( &creation_lock );
			pthread_mutex_unlock( &(send_locks[rank]) );
			break;
		}
		//pthread_mutex_unlock( &creation_lock );
		//pthread_mutex_unlock( &(send_locks[rank]) );

	}
}

int find_and_create( char *addr, int size )
{
	pthread_mutex_lock( &creation_lock );
	for( int i = 0; i < pair_size; i++ ){
		if( pair[i].isend_addr == addr && pair[i].isend_size == size ){
			pthread_mutex_unlock( &creation_lock );
			return i;
		}
	}

	if( pair_size == 0 ){
		pair = (Pair*)malloc(sizeof(Pair));

		pair[0].isend_addr = addr;
		pair[0].isend_size = size;
		pair[0].comp_addr = (char*)malloc(size + 100);
		pair[0].comp_size = size + 100;
		pair[0].ready = -1;

		pair_size = 1;
		pthread_mutex_unlock( &creation_lock );
		return -1;
	} else {
		pair = (Pair*)realloc(pair, sizeof(Pair) * (pair_size+1));

		pair[pair_size].isend_addr = addr;
		pair[pair_size].isend_size = size;
		pair[pair_size].comp_addr = (char*)malloc(size+100);
		pair[pair_size].comp_size = size + 100;
		pair[pair_size].ready = -1;

		pair_size++;
		pthread_mutex_unlock( &creation_lock );
		return -1;
	}
}


static bool IS_PROTECTED = false;
void clear_soft_dirty_bit()
{
        bool protection = IS_PROTECTED;
        IS_PROTECTED = true;

        static bool is_open = false;
        static int fd = -1;
        //if(!is_open) {
                char filename[1024] = "";
                sprintf(filename, "/proc/%d/clear_refs", getpid());

                fd = open(filename, O_WRONLY);
                is_open = true;
        //}

        if(fd < 0){
                perror("open clear_refs\n");
                return;
        }

        if(write(fd, "4", 1) != 1){
                perror("wrtie clear_refs\n");
                return;
        }

        close(fd);

        IS_PROTECTED = protection;
}

bool check_soft_dirty_bit( char *addr, int size )
{
        addr = (char*)((uint64_t)addr / PAGE_SIZE * PAGE_SIZE);
        static int pagemap_fd    = -1;
        static int kpageflags_fd = -1;
        bool dirty = false;

        char filename[1024] = "";
        sprintf(filename, "/proc/%d/pagemap", getpid());

        kpageflags_fd = open("/proc/kpageflags", O_RDONLY);
        pagemap_fd = open(filename, O_RDONLY);

        if(pagemap_fd < 0 || kpageflags_fd < 0){
                perror("open pagemap or open kflags\n");
                return false;
        }

        uint64_t start_addr = (uint64_t)addr,
                 end_addr   = (uint64_t)( (char*)addr + size );

        for( uint64_t i = start_addr; i < end_addr; i+=PAGE_SIZE ){
                uint64_t data,
                         index = (i / PAGE_SIZE) * sizeof(data);

                if(pread(pagemap_fd, &data, sizeof(data), index) != sizeof(data)){
                        perror("pread");
                        exit(0);
                }

                if(!(data & (1ULL << 63)) || (data & (1ULL << 61))){
                        continue;
                }

                dirty |= data & (1ULL << 55);
        }

        close(kpageflags_fd);
        close(pagemap_fd);

        return dirty;
}
