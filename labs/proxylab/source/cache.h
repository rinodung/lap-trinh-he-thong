/*
 * Name: Rui Hu, ID: ruihu
 * Name: Hao Gao, ID: haog
 * 
 * cache.h: header for cache
 */

#include "csapp.h"

#define MAX_CACHE_SIZE 1049000
#define MAX_OBJECT_SIZE 102400

typedef struct cache_node {
    char *id;
    struct cache_node *next;
    void *content;
    unsigned int content_length;
} cache_node;

typedef struct cache_list {
    cache_node *head;
    cache_node *rear;
    unsigned remain_length;
    sem_t r_mutex, w;
    unsigned int readcnt;
} cache_list;

/* cache helper functions*/
cache_list *init_cache();
cache_node *init_cache_node(char *id, int length);
void destory_cache_node(cache_node *node);
cache_node *search_cache_node(cache_list *list, char *id);
void add_cache_node_to_rear(cache_list *list, cache_node *node);
void add_cache_node_to_rear_sync(cache_list *list, cache_node *node);
cache_node *delete_cache_node_from_head(cache_list *list);
void evict_cache_node_lru(cache_list *list);
cache_node *delete_cache_node(cache_list *list, char *id);
void delete_cache_node_sync(cache_list *list, char *id);

/* only these two functions are called by proxy*/
int read_cache_node_lru_sync(cache_list *list, char *id,
                             void *content, unsigned int *length);
int add_content_to_cache_sync(cache_list *list, char *id,
                              void *content, unsigned int length);

/* check cache functions */
void check_cache_node(int verbose, cache_node *node);
void check_cache_list(int verbose, cache_list *list);
