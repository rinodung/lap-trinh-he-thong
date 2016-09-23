char simname[] = "Y86-64 Processor";
#include <stdio.h>
#include <stdlib.h>
long long code_val, s0_val, s1_val;
char **data_names;
/* $begin sim-mux4-s1-c */
long long gen_s1()
{
    return ((code_val) == 2 || (code_val) == 3);
}

/* $end sim-mux4-s1-c */
long long gen_s0()
{
    return ((code_val) == 1 || (code_val) == 3);
}

long long gen_Out4()
{
    return ((!(s1_val) & !(s0_val)) ? (atoll(data_names[0])) : !(s1_val) ? 
      (atoll(data_names[1])) : !(s0_val) ? (atoll(data_names[2])) : 
      (atoll(data_names[3])));
}

/* $begin sim-mux4-main-c */
int main(int argc, char *argv[]) {
  data_names = argv+2;
  code_val = atoll(argv[1]);
  s1_val = gen_s1();
  s0_val = gen_s0();
  printf("Out = %lld\n", gen_Out4());
  return 0;
}
/* $end sim-mux4-main-c */
