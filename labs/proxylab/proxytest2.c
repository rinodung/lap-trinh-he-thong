//
// Created by binhlt on 09/03/2016.
//
#include "/home/binhlt/Desktop/csapp.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#define MAX 2048
static const char *user_agent_str = "User-Agent: Mozilla/5.0 \
(X11; Linux x86_64; rv:10.0.3) PwnPP4fun/20120305 Firefox/10.0.3\r\n";
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
Powered by PwnPP4fun .</p></body></html>";

// int open_listenfd(int);
int job(int);
int forward_to_server(int , int *);
int parse_request_line(char*, char*, char*, char*, char*, char*);
void parse_host_port(char*, char*, char*);
void close_fd(int *, int *);
int forward_to_client(int , int );

int main(int argc, char ** argv){
	int listenfd, clientlen, connfd, port;
	struct sockaddr_in clientaddr;
	struct hostent *hp;
	char *nameserver;
	if(argc !=2){
		printf("USAGE : %s <port>",argv[0]);
		exit(0);
	}
	port = atoi(argv[1]);
	listenfd = open_listenfd(port);
	while(1){
		clientlen = sizeof(clientaddr);
		connfd = accept(listenfd, (struct sockaddr *) &clientaddr, &clientlen);
		hp = gethostbyaddr((const char*) &clientaddr.sin_addr.s_addr, sizeof(clientaddr.sin_addr.s_addr), AF_INET);
		nameserver = inet_ntoa(clientaddr.sin_addr);
		printf("Server connected to ... %s\n",nameserver);
		job(connfd);
	}
}

int job(int connfd){
	int to_server_fd = -1, to_client_fd = connfd, rc;
    rc = forward_to_server(to_client_fd, &to_server_fd);
	if(rc != 0){
        fprintf(stderr, "Some error has occurred or wrong method!!!\n");
        return 1;
    }
    forward_to_client(to_client_fd, to_server_fd);
    close_fd(&to_client_fd, &to_server_fd);
	return 0;
}

int forward_to_server(int fd, int *to_server_fd){
    char remote_host[MAXLINE];
    char remote_port[MAXLINE];
    char origin_request_line[MAXLINE];
    char method[MAXLINE];
    char protocol[MAXLINE];
    char host_port[MAXLINE];
    char resource[MAXLINE];
    char version[MAXLINE];
    char request_buf[MAXLINE];
	char buf[MAXLINE];
    rio_t rio_client;
    // strcpy(remote_host[MAXLINE],"");
    // strcpy(remote_port[MAXLINE],"80");
	Rio_readinitb(&rio_client, fd);
    if(Rio_readlineb(&rio_client, buf, MAX) == -1){
        return -1;
    }
    strcpy(origin_request_line,buf);
    if(parse_request_line(buf, method, protocol, host_port, resource, version) == -1){
        return -1;
    }
    parse_host_port(host_port, remote_host, remote_port);
	printf("%s  %s  %s  %s",host_port, method, remote_host, remote_port);
    if(strstr(method,"GET") == NULL){
        return -1;
    }
    // That is a GET method;
    strcpy(request_buf, method);
    strcpy(request_buf, " ");
    strcpy(request_buf, resource);
    strcpy(request_buf, " ");
    strcpy(request_buf, version);
    while(rio_readlineb(&rio_client, buf, MAX) != 0){
        if (strcmp(buf, "\r\n") == 0) {
            break;
        } else if (strstr(buf, "User-Agent:") != NULL) {
            strcat(request_buf, user_agent_str);
        } else if (strstr(buf, "Accept-Encoding:") != NULL) {
            strcat(request_buf, accept_encoding_str);
        } else if (strstr(buf, "Accept:") != NULL) {
            strcat(request_buf, accept_str);
        } else if (strstr(buf, "Connection:") != NULL) {
            strcat(request_buf, connection_str);
        } else if (strstr(buf, "Proxy Connection:") != NULL) {
            strcat(request_buf, proxy_connection_str);
        } else if (strstr(buf, "Host:") != NULL) {
            if (strlen(remote_host) < 1) {
                // if host not specified in request line
                // get host from host header
                sscanf(buf, "Host: %s", host_port);
                parse_host_port(host_port, remote_host, remote_port);
            }
            strcat(request_buf, buf);
        } else {
            strcat(request_buf, buf);
        }
    }
    // forward client to server
    *to_server_fd = open_clientfd(remote_host, atoi(remote_port));
    Rio_writen(*to_server_fd, request_buf, strlen(request_buf)) ;
    return 0;
}

int forward_to_client(int to_client_fd, int to_server_fd){
	rio_t rio_server;
    char buf[MAXLINE];
    unsigned int length = 0, size = 0;
	Rio_readlineb(&rio_server, buf, MAX);
	Rio_writen(to_client_fd, buf, strlen(buf));
	strcpy(buf ,"Test reponse\n");
	Rio_writen(to_client_fd, buf, strlen(buf));
	return 0;
}

// int open_listenfd(int port){
	// int listenfd;
	// int optval;
	// struct sockaddr_in serveraddr;
	// listenfd = socket(AF_INET, SOCK_STREAM, 0);
	// optval =1;
	// bzero((char *) &serveraddr, sizeof(serveraddr));
	// setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, (const void*) &optval, sizeof(int));
	// serveraddr.sin_family = AF_INET;
	// serveraddr.sin_port = htons(port);
	// serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
	// bind(listenfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr));
	// listen(listenfd, 5);
	// return listenfd;
// }
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
void close_fd(int *to_client_fd, int *to_server_fd) {
    if (*to_client_fd >= 0) {
        Close(*to_client_fd);
    }
    if (*to_server_fd >= 0) {
        Close(*to_server_fd);
    }
}