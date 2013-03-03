/*

LoliCore program entry point.
Chamz Lau, Copyright (C) 2013-2017
2013/02/26 20:51:04

*/

#include "co.h"

int main(int argc, const char** argv)
{
  lolicore* Co = lolicore_born(argc, argv);
  if (!Co){return 1;}
  lolicore_active(Co);
  lolicore_die(Co);
  return 0;
}
