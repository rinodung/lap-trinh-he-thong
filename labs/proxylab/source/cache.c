/*
 * Name: Rui Hu, ID: ruihu
 * Name: Hao Gao, ID: haog
 *
 * cache.c: implementation of cache
 */

#include "cache.h"

/*
 * init_cache - init a cache list
 *
 * return value: a poiner points to a cache list
 */
cache_list *init_cache() {
    cache_list *list = (cache_list *)malloc(sizeof(cache_list));

    list->head = NULL;
    list->rear = NULL;
    list->remain_length = MAX_CACHE_SIZE;

    Sem_init(&list->r_mutex, 0, 1);
    Sem_init(&list->w, 0, 1);

    list->readcnt = 0;
    return list;
}

/*
 * init_cache_node - init a cache node
 *
 * return value: a poiner points to a cache node
 */
cache_node *init_cache_node(char *id, int length) {
    cache_node *node = (cache_node *)malloc(sizeof(cache_node));

    if (node == NULL) {
        return NULL;
    }
    node->id = (char *)Malloc(sizeof(char) * (strlen(id) + 1));
    if (node->id == NULL) {
        return NULL;
    }

    strcpy(node->id, id);
    node->content_length = 0;

    node->content = Malloc(length);
    if (node->content == NULL) {
        return NULL;
    }

    node->next = NULL;

    return node;
}

/*
 * destory_cache_node - Free the cache node and its contents
 */
void destory_cache_node(cache_node *node) {
    if (node == NULL) {
        return;
    }
    Free(node->id);
    Free(node->content);
    Free(node);
}

/*
 * search_cache_node - Search for a cache node whose id is
 * equal to the specified id.
 *
 * return value: NULL if list is empty
 *               else return pointer to the cache node   
 */
cache_node *search_cache_node(cache_list *list, char *id) {
    cache_node *cur_node = list->head;
    while (cur_node != NULL) {
        if (strcmp(cur_node->id, id) == 0) {
            return cur_node;
        }
        cur_node = cur_node->next;
    }

    return NULL;
}

/*
 * add_cache_node_to_rear - Add a cache node to the rear of the
 * cache list
 */
void add_cache_node_to_rear(cache_list *list, cache_node *node) {
    if (list->head == NULL) {
        list->head = list->rear = node;
        list->remain_length -= node->content_length;
    } else {
        list->rear->next = node;
        list->rear = node;
        list->remain_length -= node->content_length;
    }
}

/*
 * add_cache_node_to_rear_sync - Evict the cache node until
 * the cache list has enough space to hold a new cache node.
 * Then add the new cache node to the rear of the cache list.
 */
void add_cache_node_to_rear_sync(cache_list *list, cache_node *node) {
    P(&(list->w));
    while (list->remain_length < node->content_length) {
        evict_cache_node_lru(list);
    }
    add_cache_node_to_rear(list, node);
    V(&(list->w));
}

/*
 * delete_cache_node_from_head - Delete a cache node from the
 * head of the cache list.
 *
 * return value: NULL if list is empty
 *               else return pointer to the cache node   
 */
cache_node *delete_cache_node_from_head(cache_list *list) {
    cache_node *cur_node = list->head;
    if (cur_node == NULL) {
        return NULL;
    }
    list->head = cur_node->next;

    list->remain_length += cur_node->content_length;

    if (cur_node == list->rear) {
        list->rear = NULL;
    }

    return cur_node;
}

/*
 * evict_cache_node_lru - Evict a cache node from the cache list
 * using a least recently used policy
 */
void evict_cache_node_lru(cache_list *list) {
    cache_node *node = delete_cache_node_from_head(list);
    destory_cache_node(node);
}

/*
 * delete_cache_node - Delete a cache node whose id is equal to the
 * specified id from the cache list
 * 
 * return value: NULL if cannot find the cache node
 *               else return pointer to the cache node   
 */
cache_node *delete_cache_node(cache_list *list, char *id) {
    cache_node *prev_node = NULL;
    cache_node *cur_node = list->head;
    while (cur_node != NULL) {
        if (strcmp(cur_node->id, id) == 0) {
            if (list->head == cur_node) {
                list->head = cur_node->next;
            }

            if (list->rear == cur_node) {
                list->rear = prev_node;
            }

            if (prev_node != NULL) {
                prev_node->next = cur_node->next;
            }

            cur_node->next = NULL;
            list->remain_length += cur_node->content_length;
            return cur_node;
        }
        prev_node = cur_node;
        cur_node = cur_node->next;
    }
    return NULL;
}

void delete_cache_node_sync(cache_list *list, char *id) {
    P(&(list->w));
    cache_node *node = delete_cache_node(list, id);
    destory_cache_node(node);
    V(&(list->w));
}

/*
 * read_cache_node_lru_sync - Write the content of the cache node
 * to the buf and the apply a LRU policy
 * return value: -1 means error
 *                0 meams correct
 */
int read_cache_node_lru_sync(cache_list *list, char *id, void *content,
                             unsigned int *length) {
    if (list == NULL) {
        return -1;
    }

    P(&(list->r_mutex));
    list->readcnt++;
    if (list->readcnt == 1) {
        P(&(list->w));
    }
    V(&(list->r_mutex));

    cache_node *node = search_cache_node(list, id);
    if (node == NULL) {
        P(&(list->r_mutex));
        list->readcnt--;
        if (list->readcnt == 0) {
            V(&(list->w));
        }
        V(&(list->r_mutex));
        return -1;
    }
    *length = node->content_length;
    memcpy(content, node->content, *length);

    P(&(list->r_mutex));
    list->readcnt--;
    if (list->readcnt == 0) {
        V(&(list->w));
    }
    V(&(list->r_mutex));

    //in order to maintain LRU policy
    P(&(list->w));
    node = delete_cache_node(list, id);
    add_cache_node_to_rear(list, node);
    V(&(list->w));
    return 0;
}

/*
 * add_content_to_cache_sync - Write the content to a cache node and
 * then add the cache node to the rear of the cache list.
 *
 * return value: -1 means error
 *                0 meams correct
 */
int add_content_to_cache_sync(cache_list *list, char *id,
                              void *content, unsigned int length) {
    if (list == NULL) {
        return -1;
    }

    cache_node *node = init_cache_node(id, length);

    if (node == NULL) {
        return -1;
    }
    memcpy(node->content, content, length);
    node->content_length = length;
    add_cache_node_to_rear_sync(list, node);
    return 0;
}

/*
 * read_cache_node_lru_sync - Read the content of the cache node to
 * the buf and the apply a LRU policy
 */
void check_cache_node(int verbose, cache_node *node) {
    if (verbose) {
        fprintf(stdout, "node id: %s\n", node->id);
        fprintf(stdout, "content length: %d\n", node->content_length);
        fprintf(stdout, "next node: %p\n", node->next);
    }
}

/*
 * check_cache_list - check the cache list and print useful
 * information to help debug
 */
void check_cache_list(int verbose, cache_list *list) {
    P(&(list->w));
    cache_node *cur_node = list->head;
    unsigned int total_length = 0;
    if (verbose) {
        fprintf(stdout, "cache list, remain length: %d\n",
                list->remain_length);
    }
    while (cur_node != NULL) {
        check_cache_node(verbose, cur_node);
        total_length += cur_node->content_length;
        if (cur_node->next == NULL) {
            if (cur_node != list->rear) {
                fprintf(stderr, "%s\n", "The rear of the list is wrong!");
            }
        }
        cur_node = cur_node->next;
    }
    if (list->remain_length + total_length != MAX_CACHE_SIZE) {
        fprintf(stderr, "%s\n",
                "The sum of the length is not equal to MAX_CACHE_SIZE");
    }
    V(&(list->w));
}
