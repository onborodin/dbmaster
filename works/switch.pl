#!/usr/local/bin/perl

use 5.010;
use Switch;


$value = 1;
     
#given($value) {
#        when(3) { say "Three"; }
#        when(7) { say "Seven"; }
#        when(9) { say "Nine"; }
#        default { say "None of the expected values"; }
#}


switch ($value) {
   case 1            { print "number 1" }
   case "a"          { print "string a" }
   case [1..10,42]   { print "number in list" }
   case (\@array)    { print "number in list" }
   case /\w+/        { print "pattern" }
   case qr/\w+/      { print "pattern" }
   case (\%hash)     { print "entry in hash" }
   case (\&sub)      { print "arg to subroutine" }
   else              { print "previous case not true" }
}


#EOF
