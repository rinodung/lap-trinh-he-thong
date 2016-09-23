/*
 * proxy.c - CS:APP Web proxy
 *
 * TEAM MEMBERS:
 *     Andrew Carnegie, ac00@cs.cmu.edu 
 *     Harry Q. Bovik, bovik@cs.cmu.edu
 * 
 * IMPORTANT: Give a high level description of your code here. You
 * must also provide a header comment at the beginning of each
 * function that describes what that function does.
 */ 

#include "csapp.h"

/* $begin solution */
/* The name of the proxy's log file */
#define PROXY_LOG "proxy.log"

/* Undefine this if you don't want debugging output */
#define DEBUG

/* 
 * This struct remembers some key attributes of an HTTP request and
 * the thread that is processing it.
 */
typedef struct {
    int myid;    /* Small integer used to identify threads in debug messages */
    int connfd;                    /* Connected file descriptor */ 
    struct sockaddr_in clientaddr; /* Client IP address */
} arglist_t;

/*
 * Globals
 */ 
FILE *log_file; /* Log file with one line per HTTP request */
sem_t mutex;    /* Semaphore mutex for whenever mutual exclusion is needed */

/*
 * Functions not provided to the students
 */
void *process_request(void* vargp);
int open_clientfd_ts(char *hostname, int port, sem_t *mutexp); 
ssize_t Rio_readn_w(int fd, void *ptr, size_t nbytes);
ssize_t Rio_readlineb_w(rio_t *rp, void *usrbuf, size_t maxlen); 
void Rio_writen_w(int fd, void *usrbuf, size_t n);

/* $end solution */
/*
 * Function prototypes
 */
int parse_uri(char *uri, char *target_addr, char *path, int  *port);
void format_log_entry(char *logstring, struct sockaddr_in *sockaddr, char *uri, int size);

/* 
 * main - Main routine for the proxy program 
 */
int main(int argc, char **argv)
{
    /* $begin solution */
    int listenfd;             /* The proxy's listening descriptor */
    int port;                 /* The port the proxy is listening on */
    pthread_t tid;            /* Pthread thread id */
    int clientlen;            /* Size in bytes of the client socket address */
    arglist_t *argp = NULL;   /* Argument struct passed to each thread */
    int request_count = 0;    /* Number of requests received so far */
    /* $end solution */

    /* Check arguments */
    if (argc != 2) {
	fprintf(stderr, "Usage: %s <port number>\n", argv[0]);
	exit(0);
    }

    /* $begin solution */
    /* 
     * Ignore any SIGPIPE signals elicited by writing to a connection
     * that has already been closed by the peer process.
     */
    signal(SIGPIPE, SIG_IGN);

    /* Create a listening descriptor */
    port = atoi(argv[1]);
    listenfd = Open_listenfd(port);

    /* Inititialize */
    log_file = Fopen(PROXY_LOG, "a");
    Sem_init(&mutex, 0, 1); /* mutex = 1 initially */
  
    /* Wait for and process client connections */
    while (1) { 
	argp = (arglist_t *)Malloc(sizeof(arglist_t));
	clientlen = sizeof(argp->clientaddr);
	argp->connfd = 
	    Accept(listenfd, (SA *)&argp->clientaddr, &clientlen);

	/* Start a new thread to process the HTTP request */
	argp->myid = request_count++;
	pthread_create(&tid, NULL, process_request, argp);
    }

    /* Control never reaches here */
    /* $end solution */
    exit(0);
}

/* $begin solution */
/*
 * process_request - Thread routine.
 * 
 * Each thread reads an HTTP request from a client, forwards it to the
 * end server (always as a simple HTTP/1.0 request), waits for the
 * response, and then forwards it back to the client.
 * 
 * Note: this function is longer than we would usually like, but
 * having everything in one function greatly simplifies error
 * handling, in particualar cleaning up after errors so as to avoid
 * memory leaks.
 */ 
void *process_request(void *vargp) 
{
    arglist_t arglist;              /* Arg list passed into thread */ 
    struct sockaddr_in clientaddr;  /* Client socket address */      
    int connfd;                     /* Socket descriptor for talking with client */
    int serverfd;                   /* Socket descriptor for talking with end server */
    char *request;                  /* HTTP request from client */
    char *request_uri;              /* Start of URI in first HTTP request header line */
    char *request_uri_end;          /* End of URI in first HTTP request header line */
    char *rest_of_request;          /* Beginning of second HTTP request header line */
    int request_len;                /* Total size of HTTP request */
    int response_len;               /* Total size in bytes of response from end server */
    int i, n;                       /* General index and counting variables */
    int realloc_factor;             /* Used to increase size of request buffer if necessary */  

    char hostname[MAXLINE];         /* Hostname extracted from request URI */
    char pathname[MAXLINE];         /* Content pathname extracted from request URI */
    int port;                       /* Port number extracted from request URI (default 80) */
    char log_entry[MAXLINE];        /* Formatted log entry */

    rio_t rio;                      /* Rio buffer for calls to buffered rio_readlineb routine */
    char buf[MAXLINE];              /* General I/O buffer */

    /* Do some initial setup */
    arglist = *((arglist_t *)vargp); /* Copy the arguments onto the stack */
    connfd = arglist.connfd;         /* Put connfd and clientaddr in scalars for convenience */  
    clientaddr = arglist.clientaddr;
    Pthread_detach(pthread_self());  /* Detach the thread */
    Free(vargp);                     /* Free up the arguments */ 

    /* 
     * Read the entire HTTP request into the request buffer, one line
     * at a time.
     */
    request = (char *)Malloc(MAXLINE);
    request[0] = '\0';
    realloc_factor = 2;
    request_len = 0;
    Rio_readinitb(&rio, connfd);
    while (1) {
	if ((n = Rio_readlineb_w(&rio, buf, MAXLINE)) <= 0) {
	    printf("process_request: client issued a bad request (1).\n");
	    close(connfd);
	    free(request);
	    return NULL;
	}

	/* If not enough room in request buffer, make more room */
	if (request_len + n + 1 > MAXLINE)
	    Realloc(request, MAXLINE*realloc_factor++);

	strcat(request, buf);
	request_len += n;

	/* An HTTP requests is always terminated by a blank line */
	if (strcmp(buf, "\r\n") == 0)
	    break;
    }
    
#if defined(DEBUG) 	
    {
	struct hostent *hp;
	char *haddrp;
	
	P(&mutex);
	hp = Gethostbyaddr((char *)&clientaddr.sin_addr.s_addr,
			   sizeof(clientaddr.sin_addr.s_addr), 
			   AF_INET);
	haddrp = inet_ntoa(clientaddr.sin_addr);
	printf("Thread %d: Received request from %s (%s):\n", arglist.myid,
	       hp->h_name, haddrp);
	printf("%s", request);
	printf("*** End of Request ***\n");
	printf("\n");
	fflush(stdout);
	V(&mutex);
    }
#endif

    /* 
     * Make sure that this is indeed a GET request
     */
    if (strncmp(request, "GET ", strlen("GET "))) {
	printf("process_request: Received non-GET request\n");
	close(connfd);
	free(request);
	return NULL;
    }
    request_uri = request + 4;

    /* 
     * Extract the URI from the request
     */
    request_uri_end = NULL;
    for (i = 0; i < request_len; i++) {
	if (request_uri[i] == ' ') {
	    request_uri[i] = '\0';
	    request_uri_end = &request_uri[i];
	    break;
	}
    }

    /* 
     * If we hit the end of the request without encountering a
     * terminating blank, then there is something screwy with the
     * request
     */
    if ( i == request_len ) {
	printf("process_request: Couldn't find the end of the URI\n");
	close(connfd);
	free(request);
	return NULL;
    }

    /*
     * Make sure that the HTTP version field follows the URI 
     */
    if (strncmp(request_uri_end + 1, "HTTP/1.0\r\n", strlen("HTTP/1.0\r\n")) &&
	strncmp(request_uri_end + 1, "HTTP/1.1\r\n", strlen("HTTP/1.1\r\n"))) {
	printf("process_request: client issued a bad request (4).\n");
	close(connfd);
	free(request);
	return NULL;
    }

    /*
     * We'll be forwarding the remaining lines in the request
     * to the end server without modification
     */
    rest_of_request = request_uri_end + strlen("HTTP/1.0\r\n") + 1;

    /* 
     * Parse the URI into its hostname, pathname, and port components.
     * Since the recipient is a proxy, the browser will always send
     * a URI consisting of a full URL "http://hostname:port/pathname"
     */  
    if (parse_uri(request_uri, hostname, pathname, &port) < 0) {
	printf("process_request: cannot parse uri\n");
	close(connfd);
	free(request);
	return NULL;
    }    

    /*
     * Forward the request to the end server
     */ 
    if ((serverfd = open_clientfd_ts(hostname, port, &mutex)) < 0) {
	printf("process_request: Unable to connect to end server.\n");
	free(request);
	return NULL;
    }
    Rio_writen_w(serverfd, "GET /", strlen("GET /"));
    Rio_writen_w(serverfd, pathname, strlen(pathname));
    Rio_writen_w(serverfd, " HTTP/1.0\r\n", strlen(" HTTP/1.0\r\n"));
    Rio_writen_w(serverfd, rest_of_request, strlen(rest_of_request));
  
#if defined(DEBUG) 	
    P(&mutex);
    printf("Thread %d: Forwarding request to end server:\n", arglist.myid);
    printf("GET /%s HTTP/1.0\r\n%s", pathname, rest_of_request);
    printf("*** End of Request ***\n");
    printf("\n");
    fflush(stdout);
    V(&mutex);
#endif

    /*
     * Receive reply from server and forward on to client
     */
    Rio_readinitb(&rio, serverfd);
    response_len = 0;
    while( (n = Rio_readn_w(serverfd, buf, MAXLINE)) > 0 ) {
	response_len += n;
	Rio_writen_w(connfd, buf, n);
#if defined(DEBUG)	
	printf("Thread %d: Forwarded %d bytes from end server to client\n", arglist.myid, n);
	fflush(stdout);
#endif
	bzero(buf, MAXLINE);
    }

    /*
     * Log the request to disk
     */
    format_log_entry(log_entry, &clientaddr, request_uri, response_len);  
    P(&mutex);
    fprintf(log_file, "%s %d\n", log_entry, response_len);
    fflush(log_file);
    V(&mutex);

    /* Clean up to avoid memory leaks and then return */
    close(connfd);
    close(serverfd);
    free(request);
    return NULL;
}

/*
 * Rio_readn_w - A wrapper function for rio_readn (csapp.c) that
 * prints a warning message when a read fails instead of terminating
 * the process.
 */
ssize_t Rio_readn_w(int fd, void *ptr, size_t nbytes) 
{
    ssize_t n;
  
    if ((n = rio_readn(fd, ptr, nbytes)) < 0) {
	printf("Warning: rio_readn failed\n");
	return 0;
    }    
    return n;
}

/*
 * Rio_readlineb_w - A wrapper for rio_readlineb (csapp.c) that
 * prints a warning when a read fails instead of terminating 
 * the process.
 */
ssize_t Rio_readlineb_w(rio_t *rp, void *usrbuf, size_t maxlen) 
{
    ssize_t rc;

    if ((rc = rio_readlineb(rp, usrbuf, maxlen)) < 0) {
	printf("Warning: rio_readlineb failed\n");
	return 0;
    }
    return rc;
} 

/*
 * Rio_writen_w - A wrapper function for rio_writen (csapp.c) that
 * prints a warning when a write fails, instead of terminating the
 * process.
 */
void Rio_writen_w(int fd, void *usrbuf, size_t n) 
{
    if (rio_writen(fd, usrbuf, n) != n) {
	printf("Warning: rio_writen failed.\n");
    }	   
}

/*
 * open_clientfd_ts - A thread safe version of the open_clientfd
 * function (csapp.c) that uses the lock-and-copy technique to deal
 * with the Class 3 thread unsafe gethostbyname function.
 */
int open_clientfd_ts(char *hostname, int port, sem_t *mutexp) 
{
    int clientfd;
    struct hostent hostent, *hp = &hostent;
    struct hostent *temp_hp;
    struct sockaddr_in serveraddr;

    if ((clientfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
	return -1; /* check errno for cause of error */

    /* Use lock-and-copy to keep this function thread safe */
    P(mutexp); /* lock */
    temp_hp = gethostbyname(hostname);
    if (temp_hp != NULL)
	hostent = *temp_hp; /* copy */
    V(mutexp);
    
    /* Fill in the server's IP address and port */
    if (temp_hp == NULL)
	return -2; /* check h_errno for cause of error */
    bzero((char *) &serveraddr, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    bcopy((char *)hp->h_addr, 
	  (char *)&serveraddr.sin_addr.s_addr, hp->h_length);
    serveraddr.sin_port = htons(port);

    /* Establish a connection with the server */
    if (connect(clientfd, (SA *) &serveraddr, sizeof(serveraddr)) < 0)
	return -1;
    return clientfd;
}

/* $end solution */

/*
 * parse_uri - URI parser
 * 
 * Given a URI from an HTTP proxy GET request (i.e., a URL), extract
 * the host name, path name, and port.  The memory for hostname and
 * pathname must already be allocated and should be at least MAXLINE
 * bytes. Return -1 if there are any problems.
 */
int parse_uri(char *uri, char *hostname, char *pathname, int *port)
{
    char *hostbegin;
    char *hostend;
    char *pathbegin;
    int len;

    if (strncasecmp(uri, "http://", 7) != 0) {
	hostname[0] = '\0';
	return -1;
    }
       
    /* Extract the host name */
    hostbegin = uri + 7;
    hostend = strpbrk(hostbegin, " :/\r\n\0");
    len = hostend - hostbegin;
    strncpy(hostname, hostbegin, len);
    hostname[len] = '\0';
    
    /* Extract the port number */
    *port = 80; /* default */
    if (*hostend == ':')   
	*port = atoi(hostend + 1);
    
    /* Extract the path */
    pathbegin = strchr(hostbegin, '/');
    if (pathbegin == NULL) {
	pathname[0] = '\0';
    }
    else {
	pathbegin++;	
	strcpy(pathname, pathbegin);
    }

    return 0;
}

/*
 * format_log_entry - Create a formatted log entry in logstring. 
 * 
 * The inputs are the socket address of the requesting client
 * (sockaddr), the URI from the request (uri), and the size in bytes
 * of the response from the server (size).
 */
void format_log_entry(char *logstring, struct sockaddr_in *sockaddr, 
		      char *uri, int size)
{
    time_t now;
    char time_str[MAXLINE];
    unsigned long host;
    unsigned char a, b, c, d;

    /* Get a formatted time string */
    now = time(NULL);
    strftime(time_str, MAXLINE, "%a %d %b %Y %H:%M:%S %Z", localtime(&now));

    /* 
     * Convert the IP address in network byte order to dotted decimal
     * form. Note that we could have used inet_ntoa, but chose not to
     * because inet_ntoa is a Class 3 thread unsafe function that
     * returns a pointer to a static variable (Ch 13, CS:APP).
     */
    host = ntohl(sockaddr->sin_addr.s_addr);
    a = host >> 24;
    b = (host >> 16) & 0xff;
    c = (host >> 8) & 0xff;
    d = host & 0xff;


    /* Return the formatted log entry string */
    sprintf(logstring, "%s: %d.%d.%d.%d %s", time_str, a, b, c, d, uri);
}


