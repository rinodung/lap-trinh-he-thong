/*
 * Name: Rui Hu, ID: ruihu
 * Name: Hao Gao, ID: haog
 *
 * proxy.c: a multithread proxy with caching capability
 * handles both GET and non GET methods
 *
 * Usage:
 * - ./proxy <port> [cache switch]
 * - cache switch: 'disable' to disable caching
 * - cache switch: omit or any other string to enable caching
 *
 * Thread safety:
 * - use getaddrinfo in CS:APP Library
 * - except cache, no other variables shared between thread
 * - pass pointers of viables in arguments list to share info
 *
 * Robust:
 * - exit thread when error happens; no way to exit process
 * - passed various tests
 *
 * Modification to CS:APP Library:
 * - use getaddrinfo for thread safety
 * - modify error functions not exit process;
 *   handled by proxy to exit thread
 * - modify Rio_writen to have return value
 * - modify Rio_writen and Rio_read** functions not to print error when
 *   errno == ECONNRESET or errno == EPIPE
 * - modify Open_clientfd to print original request line
 *   and host header(Host: xxx) when dns error;
 *   dns error happens when host cannot be found in dns server
 *   (either invalid input host or invalid host in HEAD method);
 *   our proxy will send our bad request html page as response.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "csapp.h"
#include "cache.h"

/* max times to try to malloc */
#define MAX_MALLOC 10

/* fold strings to meet 80 columns */
static const char *user_agent_str = "User-Agent: Mozilla/5.0 \
(X11; Linux x86_64; rv:10.0.3) Gecko/20120305 Firefox/10.0.3\r\n";
static const char *accept_str = "Accept: text/html,application/xhtml+xml,\
application/xml;q=0.9,*/*;q=0.8\r\n";
static const char *accept_encoding_str = "Accept-Encoding: \
gzip, deflate\r\n";
static const char *connection_str = "Connection: close\r\n";
static const char *proxy_connection_str = "Proxy-Connection: close\r\n";
static const char *http_version_str = "HTTP/1.0\r\n";
/* client_bad_request_str used when host is invalid */
static const char *client_bad_request_str = "HTTP/1.1 400 \
Bad Request\r\nServer: Apache\r\nContent-Length: 140\r\nConnection: \
close\r\nContent-Type: text/html\r\n\r\n<html><head></head><body><p>\
This webpage is not available, because DNS lookup failed.</p><p>\
Powered by Rui Hu and Gao Hao.</p></body></html>";

cache_list *cache = NULL;

/* begin of function prototypes */
void job(void *arg);
int forward_to_server(int fd, int *to_server_fd, char *cache_id,
                      void *cache_content, unsigned int *cache_length);
int forward_to_client(int to_client_fd, int to_server_fd);
int forward_to_client_from_cache(int to_client_fd, void *cache_content,
                                 unsigned int cache_length);
int forward_to_client_and_cache(int to_client_fd, int to_server_fd,
                                char *cache_id, void *cache_content);
/* helper functions */
int parse_request_line(char *buf, char *method, char *protocol,
                       char *host_port, char *resource, char *version);
void parse_host_port(char *host_port, char *remote_host, char *remote_port);
int append_content(char *content, unsigned int *content_length,
                   char *buf, unsigned int length);
void get_size(char *buf, unsigned int *size_pointer);
void close_fd(int *to_client_fd, int *to_server_fd);
/* end of function prototypes */

int main (int argc, char *argv []) {
    int listenfd, *connfd, clientlen, port = 0;
    struct sockaddr_in clientaddr;
    pthread_t tid;

    // ignore SIGPIPE
    Signal(SIGPIPE, SIG_IGN);

    // check inputs
    if (argc < 2 || argc > 3) {
        fprintf(stderr, "usage: %s <port> [cache switch]\n", argv[0]);
        fprintf(stderr, "cache switch: 'disable' to disable caching\n");
        fprintf(stderr,
            "cache switch: omit or any other string to enable caching\n");
        exit(1);
    }

    port = atoi(argv[1]);
    if (port == 0) {
        fprintf(stderr, "please enter valid port number\n");
        exit(1);
    }

    // check whether to use cache
    if (argc == 3 && strcmp(argv[2], "disable") == 0) {
        fprintf(stdout, "disable caching...\n");
    } else {
        cache = init_cache();
    }

    listenfd = Open_listenfd(port);
    if (listenfd < 0) {
        fprintf(stderr, "cannot listen to port: %d\n", port);
        exit(1);
    }

    while (1) {
        clientlen = sizeof(clientaddr);
        int count = 0;
        // use MAX_MALLOC to limit max tries
        while ((connfd = (int *)malloc(sizeof(int))) == NULL) {
            if (count > MAX_MALLOC) {
                break;
            }
            count++;
            sleep(1);
        }
        *connfd = Accept(listenfd, (SA *)&clientaddr,
                         (socklen_t *)&clientlen);
        Pthread_create(&tid, NULL, (void *)job, (void *)connfd);
    }
    return 0;
}

/*
 * job - a thread function to process http request and response
 *
 * basically it finish three tasks:
 * forward request to server when no cache hit
 * forward response to client from server or cache
 * safely close file descriptor and exit thread when error
 *
 */
void job(void *arg) {
    Pthread_detach(pthread_self());
    // get file descriptor and free the pointer
    int to_client_fd = *(int *)arg;
    Free(arg);

    int to_server_fd = -1;
    int rc = 0;
    char cache_id[MAXLINE];
    char cache_content[MAX_OBJECT_SIZE];
    unsigned int cache_length;

    rc = forward_to_server(to_client_fd, &to_server_fd, cache_id,
                           cache_content, &cache_length);
    if (rc == -1) {
        // some error
        close_fd(&to_client_fd, &to_server_fd);
        Pthread_exit(NULL);
    } else if (rc == 1) {
        // found in cache, read from cache
        if (forward_to_client_from_cache(to_client_fd, cache_content,
                                         cache_length) == -1) {
            close_fd(&to_client_fd, &to_server_fd);
            Pthread_exit(NULL);
        }
    } else if (rc == 2) {
        // non GET method, POST etc.
        if (forward_to_client(to_client_fd, to_server_fd) == -1) {
            close_fd(&to_client_fd, &to_server_fd);
            Pthread_exit(NULL);
        }
    } else {
        // GET method and write to cache
        if (forward_to_client_and_cache(to_client_fd, to_server_fd, cache_id,
                                        cache_content) == -1) {
            close_fd(&to_client_fd, &to_server_fd);
            Pthread_exit(NULL);
        }
    }
    close_fd(&to_client_fd, &to_server_fd);
    return;
}

/*
 * forward_to_server - forward the http request to server
 *
 * this function is little bit long since it handles both GET and
 * non GET methods;
 *
 * it is hard to refactor since many variables need to be passed
 *
 * return -1 when all kinds of error
 * return 0 for GET method
 * return 1 when cache hit (not forward to server)
 * return 2 for non GET method
 */
int forward_to_server(int fd, int *to_server_fd, char *cache_id,
                      void *cache_content, unsigned int *cache_length) {
    char buf[MAXLINE], request_buf[MAXLINE];
    char method[MAXLINE], protocol[MAXLINE];
    char host_port[MAXLINE];
    char remote_host[MAXLINE], remote_port[MAXLINE], resource[MAXLINE];
    char version[MAXLINE];
    char origin_request_line[MAXLINE];
    char origin_host_header[MAXLINE];

    int has_user_agent_str = 0, has_accept_str = 0,
        has_accept_encoding_str = 0,
        has_connection_str = 0, has_proxy_connection_str = 0,
        has_host_str = 0;

    rio_t rio_client;

    strcpy(remote_host, "");
    strcpy(remote_port, "80");
    memset(cache_content, 0, MAX_OBJECT_SIZE);

    Rio_readinitb(&rio_client, fd);
    if (Rio_readlineb(&rio_client, buf, MAXLINE) == -1) {
        return -1;
    }
    // used incase dns lookup failed
    strcpy(origin_request_line, buf);

    if (parse_request_line(buf, method, protocol, host_port,
                           resource, version) == -1) {
        return -1;
    }
    parse_host_port(host_port, remote_host, remote_port);

    if (strstr(method, "GET") != NULL) {
        // GET method

        // compose our request line
        strcpy(request_buf, method);
        strcat(request_buf, " ");
        strcat(request_buf, resource);
        strcat(request_buf, " ");
        strcat(request_buf, http_version_str);

        // process request header
        while (Rio_readlineb(&rio_client, buf, MAXLINE) != 0) {
            if (strcmp(buf, "\r\n") == 0) {
                break;
            } else if (strstr(buf, "User-Agent:") != NULL) {
                strcat(request_buf, user_agent_str);
                has_user_agent_str = 1;
            } else if (strstr(buf, "Accept-Encoding:") != NULL) {
                strcat(request_buf, accept_encoding_str);
                has_accept_encoding_str = 1;
            } else if (strstr(buf, "Accept:") != NULL) {
                strcat(request_buf, accept_str);
                has_accept_str = 1;
            } else if (strstr(buf, "Connection:") != NULL) {
                strcat(request_buf, connection_str);
                has_connection_str = 1;
            } else if (strstr(buf, "Proxy Connection:") != NULL) {
                strcat(request_buf, proxy_connection_str);
                has_proxy_connection_str = 1;
            } else if (strstr(buf, "Host:") != NULL) {
                strcpy(origin_host_header, buf);
                if (strlen(remote_host) < 1) {
                    // if host not specified in request line
                    // get host from host header
                    sscanf(buf, "Host: %s", host_port);
                    parse_host_port(host_port, remote_host, remote_port);
                }
                strcat(request_buf, buf);
                has_host_str = 1;
            } else {
                strcat(request_buf, buf);
            }
        }
        // if not sent, copy in out headers
        if (has_user_agent_str != 1) {
            strcat(request_buf, user_agent_str);
        }
        if (has_accept_encoding_str != 1) {
            strcat(request_buf, accept_encoding_str);
        }
        if (has_accept_str != 1) {
            strcat(request_buf, accept_str);
        }
        if (has_connection_str != 1) {
            strcat(request_buf, connection_str);
        }
        if (has_proxy_connection_str != 1) {
            strcat(request_buf, proxy_connection_str);
        }
        if (has_host_str != 1) {
            sprintf(buf, "Host: %s:%s\r\n", remote_host, remote_port);
            strcat(request_buf, buf);
        }
        strcat(request_buf, "\r\n");
        if (strcmp(remote_host, "") == 0) {
            return -1;
        }

        // compose cache id
        strcpy(cache_id, method);
        strcat(cache_id, " ");
        strcat(cache_id, remote_host);
        strcat(cache_id, ":");
        strcat(cache_id, remote_port);
        strcat(cache_id, resource);
        strcat(cache_id, " ");
        strcat(cache_id, version);

        // search in the cache
        if (read_cache_node_lru_sync(cache, cache_id, cache_content,
                                     cache_length) != -1) {
            // cache hit
            return 1;
        }

        // client to server
        *to_server_fd = Open_clientfd(remote_host, atoi(remote_port),
                                    origin_request_line, origin_host_header);
        if (*to_server_fd == -1) {
            return -1;
        } else if (*to_server_fd == -2) {
            // dns lookup failed, write our response page
            // caused by invalid host
            strcpy(buf, client_bad_request_str);
            Rio_writen(fd, buf, strlen(buf));
            return -1;
        }
        if (Rio_writen(*to_server_fd, request_buf,
                       strlen(request_buf)) == -1) {
            return -1;
        }
        return 0;
    } else {
        // non GET method
        unsigned int length = 0, size = 0;
        strcpy(request_buf, buf);
        while (strcmp(buf, "\r\n") != 0 && strlen(buf) > 0) {
            if (Rio_readlineb(&rio_client, buf, MAXLINE) == -1) {
                return -1;
            }
            if (strstr(buf, "Host:") != NULL) {
                strcpy(origin_host_header, buf);
                if (strlen(remote_host) < 1) {
                    sscanf(buf, "Host: %s", host_port);
                    parse_host_port(host_port, remote_host, remote_port);
                }
            }
            get_size(buf, &size);
            strcat(request_buf, buf);
        }
        if (strcmp(remote_host, "") == 0) {
            return -1;
        }
        *to_server_fd = Open_clientfd(remote_host, atoi(remote_port),
                                    origin_request_line, origin_host_header);
        if (*to_server_fd < 0) {
            return -1;
        }
        // write request line
        if (Rio_writen(*to_server_fd, request_buf,
                       strlen(request_buf)) == -1) {
            return -1;
        }
        // write request body
        while (size > MAXLINE) {
            if ((length = Rio_readnb(&rio_client, buf, MAXLINE)) == -1) {
                return -1;
            }
            if (Rio_writen(*to_server_fd, buf, length) == -1) {
                return -1;
            }
            size -= MAXLINE;
        }
        if (size > 0) {
            if ((length = Rio_readnb(&rio_client, buf, size)) == -1) {
                return -1;
            }
            if (Rio_writen(*to_server_fd, buf, length) == -1) {
                return -1;
            }
        }
        return 2;
    }
}

/*
 * forward_to_client - forward without write to cache
 *
 * used for non GET methods;
 *
 * return -1 on error
 * return 0 on success
 */
int forward_to_client(int to_client_fd, int to_server_fd) {
    rio_t rio_server;
    char buf[MAXLINE];
    unsigned int length = 0, size = 0;

    Rio_readinitb(&rio_server, to_server_fd);
    // forward status line
    if (Rio_readlineb(&rio_server, buf, MAXLINE) == -1) {
        return -1;
    }
    if (Rio_writen(to_client_fd, buf, strlen(buf)) == -1) {
        return -1;
    }
    // forward response headers
    while (strcmp(buf, "\r\n") != 0 && strlen(buf) > 0) {
        if (Rio_readlineb(&rio_server, buf, MAXLINE) == -1) {
            return -1;
        }
        get_size(buf, &size);
        if (Rio_writen(to_client_fd, buf, strlen(buf)) == -1) {
            return -1;
        }
    }
    // forward response body
    if (size > 0) {
        while (size > MAXLINE) {
            if ((length = Rio_readnb(&rio_server, buf, MAXLINE)) == -1) {
                return -1;
            }
            if (Rio_writen(to_client_fd, buf, length) == -1) {
                return -1;
            }
            size -= MAXLINE;
        }
        if (size > 0) {
            if ((length = Rio_readnb(&rio_server, buf, size)) == -1) {
                return -1;
            }
            if (Rio_writen(to_client_fd, buf, length) == -1) {
                return -1;
            }
        }
    } else {
        while ((length = Rio_readnb(&rio_server, buf, MAXLINE)) > 0) {
            if (Rio_writen(to_client_fd, buf, length) == -1) {
                return -1;
            }
        }
    }
    return 0;
}

/*
 * forward_to_client_from_cache - forward from cache
 *
 * return -1 on error
 * return 0 on success
 */
int forward_to_client_from_cache(int to_client_fd, void *cache_content,
                                 unsigned int cache_length) {
    // forward from cache
    if (Rio_writen(to_client_fd, cache_content, cache_length)) {
        return -1;
    }
    return 0;
}

/*
 * forward_to_client_and_cache - forward to client and write to cache
 *
 * only write to cache when size is smaller than MAX_OBJECT_SIZE
 *
 * return -1 on error
 * return 0 on success
 */
int forward_to_client_and_cache(int to_client_fd, int to_server_fd,
                                char *cache_id, void *cache_content) {
    rio_t rio_server;
    char buf[MAXLINE];
    unsigned int cache_length = 0, length = 0, size = 0;
    // if size of response larger than MAX_OBJECT_SIZE
    // valid_obj_size is set to 0
    int valid_obj_size = 1;

    Rio_readinitb(&rio_server, to_server_fd);
    // forward status line and write to cache_content
    if (Rio_readlineb(&rio_server, buf, MAXLINE) == -1) {
        return -1;
    }
    if (valid_obj_size) {
        valid_obj_size = append_content(cache_content, &cache_length, buf,
                                        strlen(buf));
    }
    if (Rio_writen(to_client_fd, buf, strlen(buf)) == -1) {
        return -1;
    }
    // forward response headers and write to cache_content
    while (strcmp(buf, "\r\n") != 0 && strlen(buf) > 0) {
        if (Rio_readlineb(&rio_server, buf, MAXLINE) == -1) {
            return -1;
        }
        get_size(buf, &size);
        if (valid_obj_size) {
            valid_obj_size = append_content(cache_content, 
                &cache_length, buf, strlen(buf));
        }
        if (Rio_writen(to_client_fd, buf, strlen(buf)) == -1) {
            return -1;
        }
    }
    // forward response body and write to cache_content
    if (size > 0) {
        while (size > MAXLINE) {
            if ((length = Rio_readnb(&rio_server, buf, MAXLINE)) == -1) {
                return -1;
            }
            if (valid_obj_size) {
                valid_obj_size = append_content(cache_content,
                                                &cache_length, buf, length);
            }
            if (Rio_writen(to_client_fd, buf, length) == -1) {
                return -1;
            }
            size -= MAXLINE;
        }
        if (size > 0) {
            if ((length = Rio_readnb(&rio_server, buf, size)) == -1) {
                return -1;
            }
            if (valid_obj_size) {
                valid_obj_size = append_content(cache_content, &cache_length,
                                                buf, length);
            }
            if (Rio_writen(to_client_fd, buf, length) == -1) {
                return -1;
            }
        }
    } else {
        while ((length = Rio_readnb(&rio_server, buf, MAXLINE)) > 0) {
            if (valid_obj_size) {
                valid_obj_size = append_content(cache_content, &cache_length,
                                                buf, length);
            }
            if (Rio_writen(to_client_fd, buf, length) == -1) {
                return -1;
            }
        }
    }
    // write cache_content to cache when size smaller than MAX_OBJECT_SIZE
    if (valid_obj_size) {
        if (add_content_to_cache_sync(cache, cache_id, cache_content,
                                      cache_length) == -1) {
            return -1;
        }
    }
    return 0;
}

/*
 * parse_request_line - parse request line to different parts
 *
 * return -1 on error
 * return 0 on success
 */
int parse_request_line(char *buf, char *method, char *protocol,
                       char *host_port, char *resource, char *version) {
    char url[MAXLINE];
    // check if it is valid buffer
    if (strstr(buf, "/") == NULL || strlen(buf) < 1) {
        return -1;
    }
    // set resource default to '/'
    strcpy(resource, "/");
    sscanf(buf, "%s %s %s", method, url, version);
    if (strstr(url, "://") != NULL) {
        // has protocol
        sscanf(url, "%[^:]://%[^/]%s", protocol, host_port, resource);
    } else {
        // no protocols
        sscanf(url, "%[^/]%s", host_port, resource);
    }
    return 0;
}

/*
 * parse_host_port - parse host:port (:port optional)to two parts
 */
void parse_host_port(char *host_port, char *remote_host, char *remote_port) {
    char *tmp = NULL;
    tmp = index(host_port, ':');
    if (tmp != NULL) {
        *tmp = '\0';
        strcpy(remote_port, tmp + 1);
    } else {
        strcpy(remote_port, "80");
    }
    strcpy(remote_host, host_port);
}

/*
 * append_content - append content to cache_content
 *
 * only append when size is smaller than MAX_OBJECT_SIZE
 *
 * return value used to set valid_obj_size in caller
 * return 0 on size exceed MAX_OBJECT_SIZE
 * return 1 on valid size
 */
int append_content(char *content, unsigned int *content_length,
                   char *buf, unsigned int length) {
    if ((*content_length + length) > MAX_OBJECT_SIZE) {
        return 0;
    }
    void *ptr = (void *)((char *)content + *content_length);
    memcpy(ptr, buf, length);
    *content_length = *content_length + length;
    return 1;
}

/*
 * get_size - get size from content-length header
 */
void get_size(char *buf, unsigned int *size_pointer) {
    if (strstr(buf, "Content-Length")) {
        sscanf(buf, "Content-Length: %d", size_pointer);
    }
}

/*
 * close_fd - safely close file descriptors
 *
 * used when thread ends or exits manually
 */
void close_fd(int *to_client_fd, int *to_server_fd) {
    if (*to_client_fd >= 0) {
        Close(*to_client_fd);
    }
    if (*to_server_fd >= 0) {
        Close(*to_server_fd);
    }
}
